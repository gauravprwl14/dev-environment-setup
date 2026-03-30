# Installing and Using the Real SDK

## Quick Install

Each example now includes the real `@agentclientprotocol/sdk` package!

### Install for All Examples

```bash
# From the acp-protocol-poc directory
cd 01-simple-message-flow && npm install && cd ..
cd 02-channel-binding && npm install && cd ..
cd 03-tool-calls && npm install && cd ..
cd 04-complete-integration && npm install
```

Or install individually:

```bash
cd 01-simple-message-flow
npm install
```

## What's Been Added

### 1. Real SDK Dependency

All `package.json` files now include:

```json
{
  "dependencies": {
    "@agentclientprotocol/sdk": "^0.16.1"
  }
}
```

### 2. New SDK-Based Examples

#### Example 1: `example-with-sdk.js`

Shows how to use `AgentSideConnection` from the real SDK:

```bash
cd 01-simple-message-flow
npm install
npm run start:real
```

**What it demonstrates:**
- Creating an ACP server with `AgentSideConnection`
- Using `ndJsonStream` for protocol handling
- Implementing ACP methods (initialize, newSession, prompt, etc.)
- Sending notifications back to clients
- Real JSON-RPC message handling

#### Example 4: `real-sdk-example.js`

Shows BOTH client and server sides:

```bash
cd 04-complete-integration
npm install
npm run start:real
```

**What it demonstrates:**
- `ClientSideConnection` - OpenClaw connecting to external agents
- `AgentSideConnection` - External agent receiving requests
- Permission request handling
- Session notifications and streaming
- Complete bidirectional flow

## SDK Components You'll Use

### From `@agentclientprotocol/sdk`:

1. **`AgentSideConnection`**
   - Use when building an ACP server
   - Receives requests from external agents
   - Example: OpenClaw receiving requests from Codex

2. **`ClientSideConnection`**
   - Use when connecting to an ACP server
   - Sends requests to external agents
   - Example: OpenClaw spawning and controlling Codex

3. **`ndJsonStream`**
   - Creates the bidirectional stream for ACP protocol
   - Handles newline-delimited JSON encoding/decoding
   - Required for both client and server

4. **`PROTOCOL_VERSION`**
   - Current protocol version ("0.1.0")
   - Use for version negotiation

5. **Type Definitions**
   - Full TypeScript types for all messages
   - `PromptRequest`, `PromptResponse`, `SessionNotification`, etc.

## Comparison: Simplified vs Real SDK

### Simplified Examples (existing)

**Files:** `example.js` in each folder

**Purpose:** Learn concepts without external dependencies

**Pros:**
- No npm install needed
- Easy to understand
- Focused on concepts

**Run:**
```bash
npm start
# or
node example.js
```

### Real SDK Examples (new)

**Files:** `example-with-sdk.js`, `real-sdk-example.js`

**Purpose:** See real SDK usage

**Pros:**
- Actual SDK code
- Production-like patterns
- Matches OpenClaw implementation

**Run:**
```bash
npm install
npm run start:real
# or
node example-with-sdk.js
```

## Learning Path

### For Beginners

1. **Start with simplified examples** (no install needed)
   ```bash
   node 01-simple-message-flow/example.js
   ```

2. **Learn the concepts** from READMEs

3. **Install SDK and run real examples**
   ```bash
   cd 01-simple-message-flow
   npm install
   npm run start:real
   ```

4. **Compare simplified vs real** to see the SDK benefits

### For Implementation

1. **Install SDK in your project**
   ```bash
   npm install @agentclientprotocol/sdk
   ```

2. **Study the real SDK examples**
   - See how connections are created
   - Understand stream setup
   - Learn permission handling

3. **Adapt patterns to your needs**
   - Use `ClientSideConnection` to spawn agents
   - Use `AgentSideConnection` to receive requests
   - Handle the specific ACP methods you need

## Real World Usage

### OpenClaw's Patterns

**Server Side** (`src/acp/server.ts`):
```typescript
import { AgentSideConnection, ndJsonStream } from "@agentclientprotocol/sdk";

const stream = ndJsonStream(
  Writable.toWeb(process.stdout),
  Readable.toWeb(process.stdin)
);

new AgentSideConnection((conn) => {
  const agent = new AcpGatewayAgent(conn, gateway, opts);
  agent.start();
  return agent;
}, stream);
```

**Client Side** (`src/acp/client.ts`):
```typescript
import { ClientSideConnection, ndJsonStream } from "@agentclientprotocol/sdk";

const proc = spawn(command, args, { stdio: ['pipe', 'pipe', 'inherit'] });

const stream = ndJsonStream(
  Writable.toWeb(proc.stdin),
  Readable.toWeb(proc.stdout)
);

const connection = new ClientSideConnection(() => ({
  agent: { name: 'openclaw', version: VERSION },
  
  async requestPermission(params) {
    // Validate and approve/deny tool calls
    return { allowed: true };
  },
  
  async sessionUpdate(notification) {
    // Handle session state changes
  }
}), stream);
```

## Troubleshooting

### "Cannot find module '@agentclientprotocol/sdk'"

**Solution:** Install dependencies:
```bash
npm install
```

### "Error: spawn ENOENT"

**Solution:** The real SDK example tries to spawn a child process. Make sure Node.js is in your PATH.

### TypeScript Errors

**Solution:** The SDK is TypeScript-native. For JavaScript usage, the types are informational only. If you want TypeScript:

```bash
npm install --save-dev typescript @types/node
```

## Next Steps

1. **Run the simplified examples** to learn concepts
2. **Install SDK and run real examples** to see actual usage
3. **Read OpenClaw's source code**:
   - [src/acp/server.ts](../../src/acp/server.ts)
   - [src/acp/client.ts](../../src/acp/client.ts)
   - [src/acp/translator.ts](../../src/acp/translator.ts)
4. **Build your own integration!**

## Quick Reference

| Example | Simplified | Real SDK | Install Needed |
|---------|-----------|----------|----------------|
| 01-simple-message-flow | `example.js` | `example-with-sdk.js` | Yes (for SDK) |
| 02-channel-binding | `example.js` | - | Yes |
| 03-tool-calls | `example.js` | - | Yes |
| 04-complete-integration | `complete-system.js` | `real-sdk-example.js` | Yes (for SDK) |

## Resources

- **SDK Docs**: [agentclientprotocol.com](https://agentclientprotocol.com/)
- **SDK Source**: [github.com/agentclientprotocol/sdk](https://github.com/agentclientprotocol/sdk)
- **OpenClaw Integration**: [SDK-INTEGRATION.md](./SDK-INTEGRATION.md)
- **Getting Started**: [GETTING-STARTED.md](./GETTING-STARTED.md)

---

**Ready to use the real SDK? Start with Example 1!**

```bash
cd 01-simple-message-flow
npm install
npm run start:real
```
