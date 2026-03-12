#!/usr/bin/env node

import 'dotenv/config';
import { publishWithRetry } from './publish-post.js';
import { searchTags } from './hashnode-client.js';
import fs from 'fs';
import path from 'path';

/**
 * CLI wrapper for creating Hashnode drafts from markdown files
 * 
 * Usage: node create-draft.js <path-to-markdown-file>
 * 
 * Expected front-matter format:
 * ---
 * title: My Article Title
 * subtitle: Optional subtitle
 * brief: Short SEO description
 * coverImage: https://cdn.example.com/cover.png
 * tags: nodejs,typescript,fintech
 * seriesId: optional-series-id
 * canonical: https://yoursite.com/original-post
 * ---
 * 
 * NOTE: This always creates a DRAFT. To publish, use publish-existing-draft.js
 */

/**
 * Parse YAML front-matter from markdown content
 * @param {string} content - Raw markdown content
 * @returns {{meta: object, body: string}} Parsed metadata and body
 */
function parseFrontMatter(content) {
  const fmRegex = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/;
  const match = content.match(fmRegex);
  
  if (!match) {
    return { meta: {}, body: content };
  }

  const metaLines = match[1].split('\n');
  const meta = {};
  
  for (const line of metaLines) {
    const colonIndex = line.indexOf(':');
    if (colonIndex === -1) continue;
    
    const key = line.slice(0, colonIndex).trim();
    const value = line.slice(colonIndex + 1).trim();
    
    if (key && value) {
      meta[key] = value;
    }
  }

  return { meta, body: match[2].trim() };
}

/**
 * Look up Hashnode tag IDs from tag names
 * @param {string[]} tagNames - Array of tag names
 * @returns {Promise<Array>} Tag objects with id, slug, name
 */
async function resolveTagIds(tagNames) {
  const tags = [];
  
  for (const name of tagNames) {
    const trimmed = name.trim();
    if (!trimmed) continue;
    
    try {
      console.log(`🔍 Looking up tag: "${trimmed}"...`);
      const results = await searchTags(trimmed, 5);
      
      if (results.length === 0) {
        console.warn(`⚠️ Tag not found: "${trimmed}" - skipping`);
        continue;
      }
      
      // Use exact match if available, otherwise first result
      const match = results.find(t => 
        t.name.toLowerCase() === trimmed.toLowerCase() ||
        t.slug.toLowerCase() === trimmed.toLowerCase()
      ) || results[0];
      
      tags.push(match);
      console.log(`✅ Found tag: ${match.name} (${match.id})`);
    } catch (err) {
      console.warn(`⚠️ Failed to lookup tag "${trimmed}": ${err.message}`);
    }
  }
  
  return tags;
}

/**
 * Main execution function
 */
async function main() {
  const filePath = process.argv[2];

  if (!filePath) {
    console.error('❌ Usage: node create-draft.js <path-to-markdown-file>');
    console.error('');
    console.error('Example:');
    console.error('  node create-draft.js ./content/my-article.md');
    console.error('');
    console.error('Required environment variables:');
    console.error('  HASHNODE_API_KEY - Your Hashnode Personal Access Token');
    console.error('  HASHNODE_PUBLICATION_ID - Your publication ID');
    console.error('');
    console.error('Note: This creates a DRAFT only. To publish:');
    console.error('  node publish-existing-draft.js <draft-slug>');
    process.exit(1);
  }

  // Validate environment
  if (!process.env.HASHNODE_API_KEY) {
    console.error('❌ Missing HASHNODE_API_KEY environment variable');
    process.exit(1);
  }

  if (!process.env.HASHNODE_PUBLICATION_ID) {
    console.error('❌ Missing HASHNODE_PUBLICATION_ID environment variable');
    process.exit(1);
  }

  // Read and parse file
  const resolvedPath = path.resolve(filePath);
  
  if (!fs.existsSync(resolvedPath)) {
    console.error(`❌ File not found: ${resolvedPath}`);
    process.exit(1);
  }

  console.log(`📖 Reading file: ${resolvedPath}`);
  const rawContent = fs.readFileSync(resolvedPath, 'utf8');
  const { meta, body } = parseFrontMatter(rawContent);

  if (!meta.title) {
    console.error('❌ Missing required front-matter field: title');
    process.exit(1);
  }

  // Parse tags
  let tags = [];
  if (meta.tags) {
    const tagNames = meta.tags.split(',').map(t => t.trim()).filter(Boolean);
    if (tagNames.length > 0) {
      console.log(`\n🏷️  Resolving ${tagNames.length} tag(s)...`);
      tags = await resolveTagIds(tagNames);
    }
  }

  // Build post object (publish field no longer used)
  const post = {
    title: meta.title,
    contentMarkdown: body,
    subtitle: meta.subtitle,
    brief: meta.brief,
    coverImageURL: meta.coverImage,
    tags,
    seriesId: meta.seriesId,
    canonicalURL: meta.canonical,
  };

  // Create draft
  console.log(`\n🚀 Creating draft on Hashnode...`);
  console.log(`   Title: ${post.title}`);
  console.log(`   Tags: ${tags.map(t => t.name).join(', ') || 'none'}`);
  console.log('');

  const result = await publishWithRetry(post);

  console.log('\n✅ Success!');
  console.log('📊 Result:', JSON.stringify(result, null, 2));
  console.log('');
  console.log(`🔗 View at: ${result.url}`);
}

// Execute
main().catch(err => {
  console.error('\n❌ Error:', err.message);
  if (process.env.DEBUG) {
    console.error(err);
  }
  process.exit(1);
});
