import 'dotenv/config';

const GQL_ENDPOINT = 'https://gql.hashnode.com';

/**
 * Make a GraphQL request to Hashnode API
 * @param {string} query - GraphQL query or mutation
 * @param {object} variables - Query variables
 * @returns {Promise<object>} Response data
 */
export async function hashnodeRequest(query, variables) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': process.env.HASHNODE_API_KEY,
  };

  let attempt = 0;
  const maxRetries = 3;

  while (attempt < maxRetries) {
    try {
      const res = await fetch(GQL_ENDPOINT, {
        method: 'POST',
        headers,
        body: JSON.stringify({ query, variables }),
      });

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }

      const json = await res.json();

      if (json.errors) {
        throw new Error(`Hashnode API Error: ${JSON.stringify(json.errors, null, 2)}`);
      }

      return json.data;
    } catch (err) {
      attempt++;
      console.warn(`⚠️ Attempt ${attempt}/${maxRetries} failed: ${err.message}`);
      
      if (attempt >= maxRetries) {
        throw new Error(`Failed after ${maxRetries} attempts: ${err.message}`);
      }

      // Exponential backoff: 2s, 4s, 8s
      const delay = 2000 * Math.pow(2, attempt - 1);
      console.log(`⏳ Retrying in ${delay}ms...`);
      await new Promise(r => setTimeout(r, delay));
    }
  }
}

/**
 * Search for Hashnode tags by name
 * @param {string} searchTerm - Tag name to search for
 * @param {number} limit - Max results (default 20)
 * @returns {Promise<Array>} Tag objects with id, name, slug
 */
export async function searchTags(searchTerm, limit = 20) {
  // Hashnode API v2 looks up tags by exact slug — there is no fuzzy search endpoint.
  // Tags in front-matter are expected to be slugs (e.g. "nodejs", "javascript").
  const query = `
    query LookupTag($slug: String!) {
      tag(slug: $slug) {
        id
        name
        slug
      }
    }
  `;

  const slug = searchTerm.toLowerCase().replace(/\s+/g, '-');
  try {
    const data = await hashnodeRequest(query, { slug });
    return data.tag ? [data.tag] : [];
  } catch {
    return [];
  }
}

/**
 * Fetch recent posts from a publication
 * @param {string} host - Publication hostname (e.g. "yourblog.hashnode.dev")
 * @param {number} count - Number of posts to fetch
 * @returns {Promise<Array>} Post objects
 */
export async function getRecentPosts(host, count = 10) {
  const query = `
    query GetPosts($host: String!, $first: Int!) {
      publication(host: $host) {
        posts(first: $first) {
          edges {
            node {
              id
              title
              slug
              url
              publishedAt
              brief
            }
          }
        }
      }
    }
  `;

  const data = await hashnodeRequest(query, { host, first: count });
  return data.publication.posts.edges.map(e => e.node);
}

/**
 * List all drafts for a publication
 * @param {string} publicationId - Publication ID
 * @param {number} limit - Max results (default 50)
 * @returns {Promise<Array>} Draft objects with id, title, slug, updatedAt
 */
export async function listDrafts(publicationId, limit = 50) {
  const query = `
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

  const data = await hashnodeRequest(query, { publicationId, first: limit });
  return data.publication.drafts.edges.map(e => e.node);
}

/**
 * Get a single draft by ID
 * @param {string} draftId - Draft ID
 * @returns {Promise<object>} Draft object
 */
export async function getDraftById(draftId) {
  const query = `
    query GetDraft($id: ID!) {
      draft(id: $id) {
        id
        title
        slug
        updatedAt
        contentMarkdown
      }
    }
  `;

  const data = await hashnodeRequest(query, { id: draftId });
  return data.draft;
}

/**
 * Publish a draft by ID
 * @param {string} draftId - Draft ID
 * @returns {Promise<object>} Published post object
 */
export async function publishDraft(draftId) {
  const mutation = `
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

  const data = await hashnodeRequest(mutation, { input: { draftId } });
  return data.publishDraft.post;
}
