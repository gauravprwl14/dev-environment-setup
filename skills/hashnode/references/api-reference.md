# Hashnode GraphQL API Reference

## Endpoint

```
https://gql.hashnode.com
```

## Authentication

All mutations (write operations) require a Personal Access Token in the `Authorization` header:

```
Authorization: <your-pat>
```

Read queries work without authentication (for public data).

## Core Mutations

### publishPost

Publish a post immediately (single-step).

```graphql
mutation PublishPost($input: PublishPostInput!) {
  publishPost(input: $input) {
    post {
      id
      url
      slug
      title
      publishedAt
    }
  }
}
```

### createDraft

Create a draft post (safer for automated workflows).

```graphql
mutation CreateDraft($input: CreateDraftInput!) {
  createDraft(input: $input) {
    draft {
      id
      slug
      title
      dateUpdated
    }
  }
}
```

### publishDraft

Publish an existing draft.

```graphql
mutation PublishDraft($input: PublishDraftInput!) {
  publishDraft(input: $input) {
    post {
      id
      url
      slug
      title
      publishedAt
    }
  }
}
```

**Variables:**
```json
{
  "input": {
    "draftId": "draft-id-from-createDraft"
  }
}
```

### updatePost

Update an existing published post.

```graphql
mutation UpdatePost($input: UpdatePostInput!) {
  updatePost(input: $input) {
    post {
      id
      title
      url
    }
  }
}
```

## Input Schema

### PublishPostInput / CreateDraftInput

```typescript
interface PublishPostInput {
  // Required
  publicationId: string;         // Your publication ID
  title: string;                 // Post title
  contentMarkdown: string;       // Full markdown content
  
  // Optional but recommended
  slug?: string;                 // Custom URL slug
  subtitle?: string;             // Subtitle displayed under title
  brief?: string;                // Short excerpt for SEO (160 chars recommended)
  
  // Cover image
  coverImageOptions?: {
    coverImageURL: string;       // Public URL to image
    isCoverAttributionHidden?: boolean;
  };
  
  // Tags
  tags?: Array<{
    id: string;                  // Hashnode tag ID (required)
    slug: string;                // Tag slug
    name: string;                // Display name
  }>;
  
  // Series
  seriesId?: string;             // Link to existing series
  
  // SEO
  metaTags?: {
    title?: string;              // Override page title
    description?: string;        // Meta description
    image?: string;              // Social share image URL
  };
  
  // Scheduling
  publishedAt?: string;          // ISO 8601 timestamp for scheduled publish
  
  // Cross-posting
  originalArticleURL?: string;   // Canonical URL for syndicated content
  
  // Settings
  settings?: {
    enableTableOfContent?: boolean;        // Auto-generate TOC
    isNewsletterActivated?: boolean;       // Send to newsletter
    delisted?: boolean;                    // Hide from feeds
  };
}
```

## Core Queries

### Get Publication Info

```graphql
query GetPublication($host: String!) {
  publication(host: $host) {
    id
    title
    displayTitle
    url
    descriptionSEO
    posts(first: 10) {
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
```

**Variables:**
```json
{
  "host": "yourblog.hashnode.dev"
}
```

### Search Tags

```graphql
query SearchTags($searchTerm: String!, $first: Int!) {
  tags(first: $first, filter: { searchTerm: $searchTerm }) {
    edges {
      node {
        id
        name
        slug
        postsCount
      }
    }
  }
}
```

**Variables:**
```json
{
  "searchTerm": "nodejs",
  "first": 20
}
```

### Get Post by Slug

```graphql
query GetPostBySlug($host: String!, $slug: String!) {
  publication(host: $host) {
    post(slug: $slug) {
      id
      title
      slug
      url
      publishedAt
      updatedAt
      brief
      content {
        markdown
        html
      }
      tags {
        id
        name
        slug
      }
      coverImage {
        url
      }
    }
  }
}
```

## Error Handling

Hashnode API returns errors in this format:

```json
{
  "errors": [
    {
      "message": "Publication not found",
      "extensions": {
        "code": "NOT_FOUND"
      }
    }
  ]
}
```

Common error codes:
- `UNAUTHENTICATED` - Missing or invalid API key
- `NOT_FOUND` - Resource doesn't exist
- `BAD_USER_INPUT` - Invalid input data
- `FORBIDDEN` - No permission for this action

## Rate Limits

Hashnode doesn't publicly document rate limits, but best practices:
- Use exponential backoff on retries
- Batch operations when possible
- Cache tag lookups
- Avoid polling; use webhooks when available

## Best Practices

1. **Use draft → publish workflow** for automated posting (safer than direct publish)
2. **Always set `brief`** for better SEO and social sharing
3. **Validate tag IDs** before publishing (use searchTags query)
4. **Use custom slugs** for predictable URLs
5. **Set canonical URLs** when cross-posting to avoid SEO penalties
6. **Include cover images** for better engagement
7. **Enable table of contents** for long-form content

## Resources

- Official API Docs: https://docs.hashnode.com/quickstart/hashnode-graphql-api-quickstart
- GraphQL Playground: https://gql.hashnode.com
- API Token Settings: https://hashnode.com/settings/developer
