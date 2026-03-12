#!/usr/bin/env node

import 'dotenv/config';
import { hashnodeRequest } from './hashnode-client.js';
import readline from 'readline';
import fs from 'fs';
import path from 'path';
import os from 'os';

// ─── GraphQL Queries ────────────────────────────────────────

const LIST_DRAFTS_QUERY = `
  query ListDrafts($publicationId: ID!, $first: Int!) {
    publication(id: $publicationId) {
      drafts(first: $first) {
        edges {
          node {
            id
            title
            slug
            updatedAt
          }
        }
      }
    }
  }
`;

const GET_DRAFT_BY_ID_QUERY = `
  query GetDraft($id: ID!) {
    draft(id: $id) {
      id
      title
      slug
    }
  }
`;

const PUBLISH_DRAFT_MUTATION = `
  mutation PublishDraft($input: PublishDraftInput!) {
    publishDraft(input: $input) {
      post {
        id
        url
        slug
        title
      }
    }
  }
`;

// ─── Helper Functions ───────────────────────────────────────

/**
 * List all drafts for the publication
 * @returns {Promise<Array>} Draft objects
 */
async function listDrafts() {
  const data = await hashnodeRequest(LIST_DRAFTS_QUERY, {
    publicationId: process.env.HASHNODE_PUBLICATION_ID,
    first: 50,
  });
  return data.publication.drafts.edges.map(e => e.node);
}

/**
 * Get draft by ID
 * @param {string} draftId - Draft ID
 * @returns {Promise<object>} Draft object
 */
async function getDraftById(draftId) {
  const data = await hashnodeRequest(GET_DRAFT_BY_ID_QUERY, { id: draftId });
  return data.draft;
}

/**
 * Find draft by slug
 * @param {string} slug - Draft slug
 * @returns {Promise<object|null>} Draft object or null
 */
async function findDraftBySlug(slug) {
  const drafts = await listDrafts();
  return drafts.find(d => d.slug === slug) || null;
}

/**
 * Publish a draft by ID
 * @param {string} draftId - Draft ID
 * @returns {Promise<object>} Published post object
 */
async function publishDraft(draftId) {
  const data = await hashnodeRequest(PUBLISH_DRAFT_MUTATION, {
    input: { draftId },
  });
  return data.publishDraft.post;
}

/**
 * Prompt user for confirmation
 * @param {string} question - Question to ask
 * @returns {Promise<boolean>} User's answer (true = yes, false = no)
 */
function askConfirmation(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    rl.question(`${question} (y/N): `, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
    });
  });
}

/**
 * Log publish action to file
 * @param {object} post - Published post object
 */
function logPublishAction(post) {
  const logDir = path.join(os.homedir(), '.openclaw', 'workspace');
  const logFile = path.join(logDir, 'hashnode-publish-log.json');

  let logs = [];
  if (fs.existsSync(logFile)) {
    try {
      logs = JSON.parse(fs.readFileSync(logFile, 'utf8'));
    } catch (err) {
      console.warn(`⚠️ Could not read log file: ${err.message}`);
    }
  }

  logs.push({
    timestamp: new Date().toISOString(),
    postId: post.id,
    title: post.title,
    slug: post.slug,
    url: post.url,
  });

  try {
    fs.mkdirSync(logDir, { recursive: true });
    fs.writeFileSync(logFile, JSON.stringify(logs, null, 2));
    console.log(`📋 Logged to: ${logFile}`);
  } catch (err) {
    console.warn(`⚠️ Could not write log: ${err.message}`);
  }
}

// ─── Main Execution ─────────────────────────────────────────

async function main() {
  const input = process.argv[2];

  // Validate environment
  if (!process.env.HASHNODE_API_KEY) {
    console.error('❌ Missing HASHNODE_API_KEY environment variable');
    process.exit(1);
  }

  if (!process.env.HASHNODE_PUBLICATION_ID) {
    console.error('❌ Missing HASHNODE_PUBLICATION_ID environment variable');
    process.exit(1);
  }

  // If no input, list drafts
  if (!input) {
    console.log('📋 Fetching drafts...\n');
    const drafts = await listDrafts();

    if (drafts.length === 0) {
      console.log('No drafts found.');
      console.log('\nCreate a draft first:');
      console.log('  node create-draft.js <markdown-file>');
      process.exit(0);
    }

    console.log(`Found ${drafts.length} draft(s):\n`);
    drafts.forEach((d, i) => {
      console.log(`${i + 1}. ${d.title}`);
      console.log(`   Slug: ${d.slug}`);
      console.log(`   ID: ${d.id}`);
      console.log(`   Updated: ${new Date(d.updatedAt).toLocaleString()}`);
      console.log('');
    });

    console.log('To publish a draft:');
    console.log('  node publish-existing-draft.js <slug-or-id>');
    process.exit(0);
  }

  // Find draft by slug or ID
  console.log(`🔍 Looking for draft: "${input}"...`);
  
  let draft;
  if (input.length > 20) {
    // Likely an ID
    try {
      draft = await getDraftById(input);
    } catch (err) {
      console.error(`❌ Draft not found with ID: ${input}`);
      process.exit(1);
    }
  } else {
    // Likely a slug
    draft = await findDraftBySlug(input);
    if (!draft) {
      console.error(`❌ Draft not found with slug: ${input}`);
      console.log('\nAvailable drafts:');
      const drafts = await listDrafts();
      drafts.forEach(d => console.log(`  - ${d.slug}`));
      process.exit(1);
    }
  }

  console.log(`✅ Found draft: "${draft.title}"`);
  console.log(`   Draft ID: ${draft.id}`);
  console.log(`   Slug: ${draft.slug}`);
  console.log('');

  // Confirmation prompt
  const confirmed = await askConfirmation(`Publish draft "${draft.title}" to Hashnode?`);
  
  if (!confirmed) {
    console.log('❌ Publish cancelled.');
    process.exit(0);
  }

  // Publish
  console.log('\n🚀 Publishing draft...');
  const post = await publishDraft(draft.id);
  
  console.log('\n✅ Published successfully!');
  console.log(`   Title: ${post.title}`);
  console.log(`   URL: ${post.url}`);
  console.log(`   Slug: ${post.slug}`);
  console.log('');

  // Log the action
  logPublishAction(post);
  
  console.log('🔗 View at:', post.url);
}

// Execute
main().catch(err => {
  console.error('\n❌ Error:', err.message);
  if (process.env.DEBUG) {
    console.error(err);
  }
  process.exit(1);
});
