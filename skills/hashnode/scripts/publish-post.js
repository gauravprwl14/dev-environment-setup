import { hashnodeRequest } from './hashnode-client.js';

// ─── GraphQL Mutations ──────────────────────────────────────

const CREATE_DRAFT_MUTATION = `
  mutation CreateDraft($input: CreateDraftInput!) {
    createDraft(input: $input) {
      draft {
        id
        slug
        title
      }
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

// ─── Main Publishing Function ───────────────────────────────

/**
 * Create a draft on Hashnode (NEVER auto-publishes)
 * 
 * @param {object} post - Post configuration
 * @param {string} post.title - Post title (REQUIRED)
 * @param {string} post.contentMarkdown - Full markdown content (REQUIRED)
 * @param {string} [post.subtitle] - Optional subtitle
 * @param {string} [post.brief] - Short excerpt/description for SEO
 * @param {string} [post.coverImageURL] - Public URL of cover image
 * @param {Array<{id: string, slug: string, name: string}>} [post.tags] - Tag objects with id, slug, name
 * @param {string} [post.seriesId] - Hashnode series ID
 * @param {string} [post.slug] - Custom URL slug
 * @param {string} [post.canonicalURL] - Original article URL for cross-posting
 * @param {object} [post.metaTags] - SEO metadata { title, description, image }
 * @param {boolean} [post.enableTableOfContent] - Auto-generate TOC (default: true)
 * @returns {Promise<object>} Draft object with id, slug, title, url
 */
export async function publishToHashnode(post) {
  const {
    title,
    contentMarkdown,
    subtitle,
    brief,
    coverImageURL,
    tags = [],
    seriesId,
    slug,
    canonicalURL,
    metaTags,
    enableTableOfContent = true,
  } = post;

  // Validate required fields
  if (!title || !contentMarkdown) {
    throw new Error('title and contentMarkdown are required');
  }

  if (!process.env.HASHNODE_PUBLICATION_ID) {
    throw new Error('HASHNODE_PUBLICATION_ID environment variable is required');
  }

  // Build input object
  const input = {
    publicationId: process.env.HASHNODE_PUBLICATION_ID,
    title,
    contentMarkdown,
    settings: {
      enableTableOfContent,
    },
  };

  // Add optional fields
  if (subtitle) input.subtitle = subtitle;
  // Note: 'brief' is not part of Hashnode's CreateDraftInput — omitted
  if (coverImageURL) {
    input.coverImageOptions = { coverImageURL };
  }
  if (tags.length > 0) input.tags = tags;
  if (seriesId) input.seriesId = seriesId;
  if (slug) input.slug = slug;
  if (canonicalURL) input.originalArticleURL = canonicalURL;
  if (metaTags) input.metaTags = metaTags;

  // Create draft only (never auto-publish)
  console.log(`📝 Creating draft: "${title}"...`);
  const draftData = await hashnodeRequest(CREATE_DRAFT_MUTATION, { input });
  const draft = draftData.createDraft.draft;
  console.log(`✅ Draft created successfully!`);
  console.log(`   Draft ID: ${draft.id}`);
  console.log(`   Slug: ${draft.slug}`);
  console.log(`   Title: ${draft.title}`);
  console.log(`\n📌 Draft saved (not published)`);
  console.log(`   To publish: node publish-existing-draft.js ${draft.slug}`);

  return {
    ...draft,
    isDraft: true,
    url: `https://hashnode.com/draft/${draft.id}`,
  };
}

/**
 * Create draft with retry logic wrapper
 * @param {object} post - Post configuration (same as publishToHashnode)
 * @param {number} maxRetries - Max retry attempts (default: 3)
 * @returns {Promise<object>} Draft object
 */
export async function publishWithRetry(post, maxRetries = 3) {
  let attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      return await publishToHashnode(post);
    } catch (err) {
      attempt++;
      console.warn(`⚠️ Draft creation attempt ${attempt}/${maxRetries} failed: ${err.message}`);
      
      if (attempt >= maxRetries) {
        throw new Error(`Failed to create draft after ${maxRetries} attempts: ${err.message}`);
      }
      
      // Exponential backoff
      const delay = 3000 * Math.pow(2, attempt - 1);
      console.log(`⏳ Retrying in ${delay}ms...`);
      await new Promise(r => setTimeout(r, delay));
    }
  }
}
