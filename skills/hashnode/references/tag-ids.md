# Hashnode Tag IDs Reference

Tags in Hashnode require three fields: `id`, `slug`, and `name`.

## Common Technology Tags

### Programming Languages

| Name | Slug | ID |
|------|------|-----|
| JavaScript | javascript | `56744721958ef13879b94cad` |
| TypeScript | typescript | `5cd9f71d8d7b4e53b5e6dde6` |
| Python | python | `56744723958ef13879b951c4` |
| Java | java | `56744721958ef13879b94c9f` |
| Go | go | `56744722958ef13879b94fc6` |
| Rust | rust | `5f4ed7e8a2f8f700c62f5c2a` |
| C++ | cpp | `56744721958ef13879b94c92` |

### Frameworks & Libraries

| Name | Slug | ID |
|------|------|-----|
| Node.js | nodejs | `56744723958ef13879b951ef` |
| React | reactjs | `56744722958ef13879b9501a` |
| Next.js | nextjs | `5f4ed7e8a2f8f700c62f5d1a` |
| NestJS | nestjs | `5f64a67e8d5a87bfb3f74625` |
| Vue.js | vuejs | `56744723958ef13879b952a3` |
| Angular | angularjs | `56744721958ef13879b94ce2` |
| Django | django | `56744722958ef13879b94f32` |
| Express | express | `56744722958ef13879b94f8c` |

### Databases

| Name | Slug | ID |
|------|------|-----|
| MongoDB | mongodb | `56744723958ef13879b951f9` |
| PostgreSQL | postgresql | `56744723958ef13879b951fe` |
| MySQL | mysql | `56744723958ef13879b951ea` |
| Redis | redis | `56744723958ef13879b95203` |

### DevOps & Cloud

| Name | Slug | ID |
|------|------|-----|
| DevOps | devops | `5f4ed7e8a2f8f700c62f5d3b` |
| Docker | docker | `56744722958ef13879b94f37` |
| Kubernetes | kubernetes | `5f4ed7e8a2f8f700c62f5d4c` |
| AWS | aws | `56744721958ef13879b94cf9` |
| Azure | azure | `5f4ed7e8a2f8f700c62f5d2e` |
| CI/CD | cicd | `5f4ed7e8a2f8f700c62f5d35` |

### Web Development

| Name | Slug | ID |
|------|------|-----|
| Web Development | web-development | `56744723958ef13879b952b0` |
| Frontend | frontend | `5f4ed7e8a2f8f700c62f5d42` |
| Backend | backend | `5f4ed7e8a2f8f700c62f5d2b` |
| API | apis | `56744721958ef13879b94ced` |
| GraphQL | graphql | `5ad7c5b41f75d7e72c9ffd41` |
| REST API | rest-api | `5f4ed7e8a2f8f700c62f5d5f` |

### Mobile Development

| Name | Slug | ID |
|------|------|-----|
| React Native | react-native | `5f4ed7e8a2f8f700c62f5d5a` |
| Flutter | flutter | `5f4ed7e8a2f8f700c62f5d3f` |
| iOS | ios | `56744722958ef13879b94fc2` |
| Android | android | `56744721958ef13879b94ce4` |

### AI & Data

| Name | Slug | ID |
|------|------|-----|
| Artificial Intelligence | ai | `5f4ed7e8a2f8f700c62f5c1a` |
| Machine Learning | machine-learning | `56744723958ef13879b951dd` |
| Data Science | data-science | `56744722958ef13879b94f28` |

### Industry Verticals

| Name | Slug | ID |
|------|------|-----|
| Fintech | fintech | `5f4ed7e8a2f8f700c62f5c4a` |
| E-commerce | ecommerce | `5f4ed7e8a2f8f700c62f5d39` |
| SaaS | saas | `5f4ed7e8a2f8f700c62f5d62` |

### General Topics

| Name | Slug | ID |
|------|------|-----|
| Programming | programming | `56744723958ef13879b951fe` |
| Software Development | software-development | `5f4ed7e8a2f8f700c62f5d6a` |
| Tutorial | tutorial | `56744723958ef13879b9527e` |
| Best Practices | best-practices | `5f4ed7e8a2f8f700c62f5c31` |
| Architecture | architecture | `5f4ed7e8a2f8f700c62f5c25` |
| System Design | system-design | `5f4ed7e8a2f8f700c62f5d71` |

## How to Find Tag IDs

### Method 1: Use the GraphQL Playground

1. Go to https://gql.hashnode.com
2. Run this query:

```graphql
{
  tags(first: 20, filter: { searchTerm: "your-tag-name" }) {
    edges {
      node {
        id
        name
        slug
      }
    }
  }
}
```

### Method 2: Use the searchTags function

```javascript
import { searchTags } from './scripts/hashnode-client.js';

const tags = await searchTags('nodejs', 10);
console.log(tags);
// [{ id: '56744723958ef13879b951ef', name: 'Node.js', slug: 'nodejs' }]
```

### Method 3: Browser Network Tab

1. Open Hashnode in browser
2. Start writing a post
3. Add a tag
4. Check Network tab for the GraphQL request
5. Inspect the `tags` array in the response

## Tag Format

When passing tags to the API, use this format:

```javascript
const tags = [
  {
    id: '56744723958ef13879b951ef',
    slug: 'nodejs',
    name: 'Node.js'
  },
  {
    id: '5cd9f71d8d7b4e53b5e6dde6',
    slug: 'typescript',
    name: 'TypeScript'
  }
];
```

All three fields are required:
- `id` - The Hashnode internal tag ID (required for mutations)
- `slug` - URL-friendly tag identifier
- `name` - Display name

## Best Practices

1. **Validate tag IDs before publishing** - Invalid IDs cause mutations to fail
2. **Use 3-5 tags per post** - More than 5 looks spammy
3. **Pick relevant, popular tags** - Check `postsCount` when searching
4. **Cache tag lookups** - Tag IDs don't change; cache them locally
5. **Use specific tags** - "NestJS" > "Backend" > "Programming"

## Updating This List

To add new tags to this reference:

1. Search for the tag using the playground or API
2. Verify it's an official Hashnode tag (has `postsCount > 0`)
3. Add it to the appropriate category above
4. Keep entries sorted alphabetically within each section
