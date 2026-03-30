# Example 4: Complete Integration

## What This Shows

This brings together everything from Examples 1-3 into a complete, working system that demonstrates the full ACP flow from end to end.

## Two Versions Available

### 1. Simplified Simulation
**File:** `complete-system.js`

Simulates the complete system with no dependencies:
```bash
node complete-system.js
```

### 2. Real SDK Integration
**File:** `real-sdk-example.js`

Uses the actual `@agentclientprotocol/sdk` to show both client and server:
```bash
npm install
npm run start:real
```

The real SDK version demonstrates:
- ✅ `ClientSideConnection` (OpenClaw → External Agent)
- ✅ `AgentSideConnection` (External Agent receives requests)
- ✅ Permission request handling
- ✅ Session notifications and streaming
- ✅ Complete bidirectional protocol

This is **exactly** how OpenClaw integrates external agents!

## The Complete Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Complete ACP System                          │
└─────────────────────────────────────────────────────────────────────┘

1. Message arrives from Discord
         ↓
2. Binding Manager routes to session
         ↓
3. Session Manager loads history
         ↓
4. Agent processes message
         ↓
5. Agent makes tool calls (read_file, search, etc.)
         ↓
6. Tool System executes with results
         ↓
7. Agent streams response back
         ↓
8. Gateway sends to Discord
```

## Running the Complete System

```bash
cd 04-complete-integration
npm install
npm start
```

This will run a complete simulation showing:
1. Multiple channels (Discord, Telegram)
2. Persistent and dynamic bindings
3. Agent sessions with history
4. Tool calls in action
5. Streaming responses
6. Error handling

## Implementation Guide for Your Project

Want to add ACP to your own project? Follow this guide...

### Step 1: Install Dependencies

```bash
npm install @agentclientprotocol/sdk
```

### Step 2: Implement the AcpRuntime Interface

```typescript
import type { AcpRuntime, AcpRuntimeHandle, AcpRuntimeEvent } from '@agentclientprotocol/sdk';

class MyAcpRuntime implements AcpRuntime {
  async ensureSession(input) {
    // Create or get existing session
    // Return a handle
  }

  async *runTurn(input) {
    // Stream events: text_delta, tool_call, done, error
  }

  async cancel(handle) {
    // Cancel ongoing work
  }

  async close(handle) {
    // Cleanup session
  }
}
```

### Step 3: Create a Binding Manager

```typescript
class BindingManager {
  // Map conversations to sessions
  resolveBinding(channel, accountId, conversationId) {
    // Return which session to use
  }
}
```

### Step 4: Wire Up Message Reception

```typescript
// When message arrives from Discord/Telegram/etc
async function handleIncomingMessage(channel, accountId, conversationId, text) {
  // 1. Resolve binding
  const binding = bindingManager.resolveBinding(channel, accountId, conversationId);
  
  // 2. Get session handle
  const handle = await runtime.ensureSession({
    sessionKey: binding.targetSessionKey,
    agent: binding.backend,
    mode: binding.mode
  });
  
  // 3. Run turn and stream back
  for await (const event of runtime.runTurn({ handle, text })) {
    if (event.type === 'text_delta') {
      await sendToChannel(channel, conversationId, event.text);
    }
  }
}
```

### Step 5: Set Up Configuration

```json
{
  "bindings": [
    {
      "type": "acp",
      "match": {
        "channel": "discord",
        "peer": { "id": "your-channel-id" }
      },
      "agentId": "main",
      "acp": {
        "mode": "persistent",
        "backend": "codex"
      }
    }
  ]
}
```

### Key Design Decisions

#### 1. Session Storage

**Option A: In-Memory** (simple, good for POC)
```typescript
private sessions = new Map<string, Session>();
```

**Option B: File-Based** (persistent)
```typescript
// Store as JSONL
// ~/.myapp/sessions/<sessionId>.jsonl
```

**Option C: Database** (production)
```typescript
// PostgreSQL, MongoDB, etc.
```

#### 2. Tool Security

**Always validate:**
- Tool is allowed
- Params are safe
- Paths are within workspace
- Rate limit tool calls

```typescript
async executeTool(toolName, params) {
  // Check allowlist
  if (!this.allowedTools.has(toolName)) {
    throw new Error('Tool not permitted');
  }
  
  // Validate paths
  if (toolName === 'read_file') {
    if (!isWithinWorkspace(params.path)) {
      throw new Error('Path outside workspace');
    }
  }
  
  // Execute
  return await this.tools.get(toolName).handler(params);
}
```

#### 3. Error Handling

**Stream errors to user:**
```typescript
try {
  // ... do work ...
} catch (error) {
  yield {
    type: 'error',
    message: error.message,
    code: error.code,
    retryable: error.retryable
  };
}
```

#### 4. Cancellation

**Support AbortSignal:**
```typescript
async *runTurn(input) {
  const { signal } = input;
  
  if (signal?.aborted) {
    throw new Error('Cancelled');
  }
  
  // Check signal throughout execution
  for await (const chunk of heavyOperation()) {
    if (signal?.aborted) {
      yield { type: 'error', message: 'Cancelled by user' };
      return;
    }
    yield chunk;
  }
}
```

## Architecture Patterns

### Pattern 1: Single Agent
```
All users → One ACP session → One agent
```
Simple, but no isolation between users.

### Pattern 2: Per-User Agents
```
User A → Session A → Agent A
User B → Session B → Agent B
```
Good isolation, scales well.

### Pattern 3: Per-Channel Agents
```
Discord → Sessions... → Codex
Telegram → Sessions... → Claude
Slack → Sessions... → Gemini
```
Different agents for different channels.

### Pattern 4: Dynamic Agents
```
/acp spawn codex → New session → Codex
/acp spawn claude → New session → Claude
```
Users choose agents on demand.

## Testing Your Integration

### Test 1: Basic Message Flow
```typescript
const handle = await runtime.ensureSession({
  sessionKey: 'test:session:1',
  agent: 'test',
  mode: 'persistent'
});

for await (const event of runtime.runTurn({
  handle,
  text: 'Hello'
})) {
  console.log(event);
}
```

### Test 2: Tool Calls
```typescript
// Verify tools work
const result = await toolSystem.executeTool('read_file', {
  path: 'test.ts'
});

assert(result.success);
assert(result.content.length > 0);
```

### Test 3: Bindings
```typescript
// Add binding
bindingManager.addPersistentBinding({
  channel: 'test',
  accountId: 'bot',
  conversationId: 'chan-1',
  backend: 'test-agent'
});

// Resolve
const binding = bindingManager.resolveBinding('test', 'bot', 'chan-1');
assert(binding !== null);
```

### Test 4: Session Persistence
```typescript
// Create session, add message, close
const session1 = await runtime.ensureSession({...});
await runtime.runTurn({ handle: session1, text: 'Test' });
await runtime.close(session1);

// Reopen, verify history
const session2 = await runtime.ensureSession({
  sessionKey: session1.sessionKey, // Same key
  ...
});
// Should have previous messages
```

## Performance Tips

### 1. Session Pooling
```typescript
// Keep hot sessions in memory
private hotSessions = new LRU<string, Session>({ max: 100 });
```

### 2. Lazy Loading
```typescript
// Load history only when needed
async loadHistory(sessionKey) {
  if (this.historyCache.has(sessionKey)) {
    return this.historyCache.get(sessionKey);
  }
  const history = await this.loadFromDisk(sessionKey);
  this.historyCache.set(sessionKey, history);
  return history;
}
```

### 3. Batch Tool Calls
```typescript
// If agent wants multiple reads, batch them
async executeBatch(toolCalls) {
  return Promise.all(toolCalls.map(call =>
    this.executeTool(call.name, call.params)
  ));
}
```

### 4. Streaming Optimization
```typescript
// Send delta only when meaningful
let buffer = '';
for (const char of response) {
  buffer += char;
  if (buffer.length >= 50 || char === '\n') {
    yield { type: 'text_delta', text: buffer };
    buffer = '';
  }
}
```

## Security Checklist

- [ ] Validate all tool params
- [ ] Sandbox file operations
- [ ] Rate limit tool calls
- [ ] Rate limit messages per user
- [ ] Validate session ownership
- [ ] Encrypt sensitive data
- [ ] Log security events
- [ ] Set tool timeouts
- [ ] Restrict dangerous tools
- [ ] Validate file paths (no ../)

## Production Considerations

### 1. Logging
```typescript
logger.info('ACP turn started', {
  sessionKey: handle.sessionKey,
  backend: handle.backend,
  messageLength: text.length
});
```

### 2. Metrics
```typescript
metrics.increment('acp.turns.started');
metrics.timing('acp.turn.duration', duration);
metrics.gauge('acp.active_sessions', activeSessions.size);
```

### 3. Error Recovery
```typescript
// Retry transient errors
for (let i = 0; i < 3; i++) {
  try {
    return await operation();
  } catch (err) {
    if (!err.retryable || i === 2) throw err;
    await sleep(1000 * Math.pow(2, i));
  }
}
```

### 4. Graceful Shutdown
```typescript
async shutdown() {
  // Stop accepting new messages
  this.accepting = false;
  
  // Wait for ongoing turns
  await Promise.all(this.activeTurns);
  
  // Close all sessions gracefully
  for (const handle of this.sessions.values()) {
    await this.runtime.close(handle, 'shutdown');
  }
}
```

## Key Takeaways

1. **ACP is a protocol**: Standardizes agent communication
2. **Bindings are routing**: Map conversations to sessions
3. **Sessions are state**: Keep conversation history
4. **Tools are actions**: What agents can do
5. **Streaming is UX**: Show progress in real-time

## Real OpenClaw References

- Runtime interface: [src/acp/runtime/types.ts](../../src/acp/runtime/types.ts)
- Bindings: [src/acp/persistent-bindings.types.ts](../../src/acp/persistent-bindings.types.ts)
- Translator: [src/acp/translator.ts](../../src/acp/translator.ts)
- Server: [src/acp/server.ts](../../src/acp/server.ts)
- Client: [src/acp/client.ts](../../src/acp/client.ts)

---

🔗 [← Back](../03-tool-calls/) | [Main README](../README.md)

**You've completed the ACP guide!** 🎉

You now understand:
- ✅ How ACP works
- ✅ How agents and sessions relate
- ✅ How channel bindings route messages
- ✅ How tool calls execute
- ✅ How to implement ACP in your project

Start building! 🚀
