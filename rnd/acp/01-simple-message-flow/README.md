# Example 1: Simple Message Flow

## What This Example Shows

This demonstrates the most basic ACP flow:
1. A user sends a message
2. OpenClaw receives it
3. It's routed to an agent
4. The agent responds
5. The response goes back to the user

## Two Versions Available

### 1. Simplified Version (No Dependencies)
**File:** `example.js`

Learn the concepts without npm install:
```bash
node example.js
```

### 2. Real SDK Version (With Dependencies)
**File:** `example-with-sdk.js`

See the actual `@agentclientprotocol/sdk` in action:
```bash
npm install
npm run start:real
```

The real SDK version uses:
- `AgentSideConnection` - Real ACP server
- `ndJsonStream` - Protocol streaming
- Actual JSON-RPC handling
- Same patterns as OpenClaw!

## The Flow Visualized

```
User                OpenClaw              Agent
  |                    |                    |
  |--"Hello Agent"---->|                    |
  |                    |                    |
  |                    |--ensureSession---->|
  |                    |<---sessionHandle---|
  |                    |                    |
  |                    |--runTurn---------->|
  |                    |  (prompt: "Hello") |
  |                    |                    |
  |                    |<--text_delta-------|
  |                    |<--text_delta-------|
  |                    |<--done-------------|
  |                    |                    |
  |<-"Hi! How can I..."|                    |
  |                    |                    |
```

## Code Walkthrough

### 1. Simplified ACP Types (types.ts)

```typescript
// Core types you need to understand

// Represents an active session
type SessionHandle = {
  sessionKey: string;      // Unique identifier
  backend: string;         // Which agent system (e.g., "codex")
  runtimeSessionName: string;  // Human-readable name
  cwd?: string;           // Working directory
};

// Input to create/get a session
type EnsureSessionInput = {
  sessionKey: string;     // Where to store this conversation
  agent: string;          // Which agent to use (codex, claude, etc.)
  mode: "persistent" | "oneshot";  // Keep history or one-off?
  cwd?: string;          // Working directory for agent
};

// Input to send a message
type TurnInput = {
  handle: SessionHandle;  // Which session
  text: string;          // The message
  mode: "prompt" | "steer";  // New message or steer current?
};

// Events streamed back from agent
type RuntimeEvent = 
  | { type: "text_delta"; text: string }  // Partial response
  | { type: "tool_call"; text: string }   // Agent using a tool
  | { type: "done"; stopReason?: string } // Finished
  | { type: "error"; message: string };   // Something went wrong
```

### 2. Simple Agent Implementation (simple-agent.ts)

```typescript
/**
 * Simplified agent that demonstrates the core concepts
 * In reality, this would connect to Codex, Claude, etc.
 */

class SimpleAgent {
  private sessions = new Map<string, Message[]>();

  /**
   * Step 1: Ensure a session exists
   * This is like opening a conversation thread
   */
  async ensureSession(input: EnsureSessionInput): Promise<SessionHandle> {
    const { sessionKey, agent, mode } = input;

    // Create session if it doesn't exist
    if (!this.sessions.has(sessionKey)) {
      console.log(`📝 Creating new ${mode} session: ${sessionKey}`);
      this.sessions.set(sessionKey, []);
    }

    // Return a handle to reference this session
    return {
      sessionKey,
      backend: agent,
      runtimeSessionName: `session-${sessionKey.split(':').pop()}`,
      cwd: input.cwd || process.cwd()
    };
  }

  /**
   * Step 2: Run a turn (send a message and get response)
   * This is the core of the interaction
   */
  async *runTurn(input: TurnInput): AsyncIterable<RuntimeEvent> {
    const { handle, text } = input;
    const sessionKey = handle.sessionKey;

    console.log(`💬 Processing message in ${sessionKey}`);
    console.log(`   User: ${text}`);

    // Add user message to history
    const history = this.sessions.get(sessionKey) || [];
    history.push({ role: 'user', content: text });

    // Simulate agent "thinking" and responding
    yield { type: 'text_delta', text: 'Hello! ' };
    await sleep(100);

    yield { type: 'text_delta', text: 'I received your message: "' };
    await sleep(100);

    yield { type: 'text_delta', text: text };
    await sleep(100);

    yield { type: 'text_delta', text: '"' };
    await sleep(100);

    // Add assistant response to history
    const response = `Hello! I received your message: "${text}"`;
    history.push({ role: 'assistant', content: response });

    console.log(`   Agent: ${response}`);

    // Signal completion
    yield { type: 'done', stopReason: 'end_turn' };
  }

  /**
   * Step 3: Cancel an ongoing turn
   */
  async cancel(handle: SessionHandle): Promise<void> {
    console.log(`🛑 Cancelling session: ${handle.sessionKey}`);
  }

  /**
   * Step 4: Close and cleanup a session
   */
  async close(handle: SessionHandle): Promise<void> {
    console.log(`👋 Closing session: ${handle.sessionKey}`);
    this.sessions.delete(handle.sessionKey);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

type Message = {
  role: 'user' | 'assistant';
  content: string;
};
```

### 3. Using the Agent (example.ts)

```typescript
async function demonstrateSimpleFlow() {
  const agent = new SimpleAgent();

  console.log('🚀 Starting Simple Message Flow Demo\n');

  // Step 1: Create a session
  console.log('Step 1: Creating session...');
  const handle = await agent.ensureSession({
    sessionKey: 'agent:main:demo:user123',
    agent: 'simple-demo-agent',
    mode: 'persistent'
  });
  console.log('✅ Session created!\n');

  // Step 2: Send first message
  console.log('Step 2: Sending first message...');
  let fullResponse = '';
  for await (const event of agent.runTurn({
    handle,
    text: 'Hello Agent!',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      fullResponse += event.text;
      process.stdout.write(event.text);  // Live streaming!
    } else if (event.type === 'done') {
      console.log('\n✅ First message complete!\n');
    }
  }

  // Step 3: Send follow-up message (uses same session)
  console.log('Step 3: Sending follow-up message...');
  fullResponse = '';
  for await (const event of agent.runTurn({
    handle,
    text: 'Can you help me with code?',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      fullResponse += event.text;
      process.stdout.write(event.text);
    } else if (event.type === 'done') {
      console.log('\n✅ Follow-up complete!\n');
    }
  }

  // Step 4: Close session
  console.log('Step 4: Closing session...');
  await agent.close(handle);
  console.log('✅ Session closed!\n');

  console.log('🎉 Demo complete!');
}

// Run it!
demonstrateSimpleFlow().catch(console.error);
```

## Running the Example

```bash
cd 01-simple-message-flow
npm install
npm start
```

**Expected output:**
```
🚀 Starting Simple Message Flow Demo

Step 1: Creating session...
📝 Creating new persistent session: agent:main:demo:user123
✅ Session created!

Step 2: Sending first message...
💬 Processing message in agent:main:demo:user123
   User: Hello Agent!
Hello! I received your message: "Hello Agent!"
   Agent: Hello! I received your message: "Hello Agent!"
✅ First message complete!

Step 3: Sending follow-up message...
💬 Processing message in agent:main:demo:user123
   User: Can you help me with code?
Hello! I received your message: "Can you help me with code?"
   Agent: Hello! I received your message: "Can you help me with code?"
✅ Follow-up complete!

Step 4: Closing session...
👋 Closing session: agent:main:demo:user123
✅ Session closed!

🎉 Demo complete!
```

## Key Takeaways

1. **Sessions are persistent**: Messages build on previous context
2. **Streaming is core**: Responses come as deltas, not all at once
3. **SessionKey is important**: It's how we identify and route conversations
4. **Handles connect everything**: You get a handle from `ensureSession`, use it for `runTurn`

## What's Different in Real OpenClaw?

This simplified example shows the concepts. In real OpenClaw:

1. **Multiple backends**: Can connect to Codex, Claude, Gemini, etc.
2. **Session persistence**: History saved to disk as JSONL
3. **Tool execution**: Agents can read files, run commands, etc.
4. **Channel routing**: Maps Discord/Telegram/Slack messages to sessions
5. **Error handling**: Robust retry, timeout, and error recovery
6. **Security**: Permission checks, sandboxing, rate limiting

## Next Steps

- **Example 2**: Learn how channel bindings route messages
- **Example 3**: See how sessions are managed long-term
- **Example 4**: Explore tool calls in depth
- **Example 5**: See the complete integration

---

🔗 [Back to Main README](../README.md) | [Next: Channel Binding →](../02-channel-binding/)
