# ACP Protocol POC - Complete Guide

## 🎯 What You've Created

This POC folder contains everything you need to understand how OpenClaw uses the Agent Client Protocol (ACP) to integrate external coding agents.

## 📁 Folder Structure

```
acp-protocol-poc/
├── README.md                      # Main guide - start here!
├── SDK-INTEGRATION.md             # How @agentclientprotocol/sdk is used
├── 01-simple-message-flow/        # Example 1: Basic concepts
│   ├── README.md
│   ├── example.js                 # Runnable demo
│   └── package.json
├── 02-channel-binding/            # Example 2: Message routing
│   ├── README.md
│   ├── example.js                 # Runnable demo
│   └── package.json
├── 03-tool-calls/                 # Example 3: Agent actions
│   ├── README.md
│   ├── example.js                 # Runnable demo
│   └── package.json
└── 04-complete-integration/       # Example 4: Everything together
    ├── README.md
    ├── complete-system.js         # Runnable demo
    └── package.json
```

## 🚀 Quick Start

### Run All Examples

```bash
# Example 1: Simple message flow
cd acp-protocol-poc/01-simple-message-flow
node example.js

# Example 2: Channel bindings
cd ../02-channel-binding
node example.js

# Example 3: Tool calls
cd ../03-tool-calls
node example.js

# Example 4: Complete integration
cd ../04-complete-integration
node complete-system.js
```

Each example builds on the previous one, showing progressively more complex concepts.

## 📚 Learning Path

### For Absolute Beginners

1. **Start with [README.md](./README.md)**
   - Read the "Core Concepts Explained Simply" section
   - Understand the message flow diagram
   - Review the FAQ

2. **Run Example 1**
   ```bash
   cd 01-simple-message-flow
   node example.js
   ```
   - Watch how sessions work
   - See streaming in action
   - Understand the basic flow

3. **Read Example 1's README**
   - Understand `ensureSession`, `runTurn`, `close`
   - Learn about event types (`text_delta`, `done`)
   - Compare to real OpenClaw implementation

4. **Move to Example 2**
   - Learn how channels route to sessions
   - Understand persistent vs dynamic bindings
   - See multi-channel scenarios

5. **Continue through Examples 3 & 4**

### For Implementing ACP in Your Project

1. **Read [SDK-INTEGRATION.md](./SDK-INTEGRATION.md)**
   - Understand how `@agentclientprotocol/sdk` works
   - See real integration examples from OpenClaw
   - Learn the client vs server patterns

2. **Review Example 4's Implementation Guide**
   - Step-by-step implementation checklist
   - Design decisions explained
   - Production considerations

3. **Study OpenClaw's Real Code**
   - `src/acp/server.ts` - Server-side integration
   - `src/acp/client.ts` - Client-side integration
   - `src/acp/translator.ts` - Protocol translation

## 🔑 Key Concepts Explained

### 1. ACP (Agent Client Protocol)

**What it is:** A standardized protocol (like HTTP for web) that lets different coding agents communicate with tools like OpenClaw.

**Why it matters:** Without ACP, OpenClaw would need custom integrations for each agent (Codex, Claude, Gemini). With ACP, they all speak the same language.

### 2. Sessions

**What it is:** A conversation container that holds all messages and context.

**Key insight:** Sessions are identified by keys like `agent:main:acp:discord:abc123`. Same key = same conversation.

### 3. Bindings

**What it is:** The routing table that maps messaging channels to agent sessions.

**Types:**
- **Persistent** (from config): Long-term, survive restarts
- **Dynamic** (runtime): Created on-the-fly, like `/acp spawn`

### 4. Tool Calls

**What it is:** Actions agents can perform (read files, run commands, search).

**How it works:** Agent requests → Permission check → Execute → Return result

### 5. The @agentclientprotocol/sdk Package

**What it provides:**
- `AgentSideConnection`: Act as ACP server (receive agent connections)
- `ClientSideConnection`: Act as ACP client (connect to agents)
- `ndJsonStream`: Handle protocol streaming
- Type definitions for everything

**How OpenClaw uses it:**
- **Server mode**: External agents connect to OpenClaw
- **Client mode**: OpenClaw spawns external agents
- **Both**: Full bidirectional integration

## 🎓 Understanding the Flow

### User Sends Message → Agent Responds

```
1. User types in Discord: "Fix the bug"
         ↓
2. Discord → OpenClaw Gateway (WebSocket)
         ↓
3. Gateway → Binding Manager
         ↓
4. Binding Manager: "This channel → session:abc123"
         ↓
5. Session Manager: Load history for session:abc123
         ↓
6. ACP Runtime: Spawn/connect to Codex agent
         ↓
7. @agentclientprotocol/sdk: Send ACP message
         ↓
8. Codex: "Let me read the file..."
         ↓
9. Tool Call: read_file(path="bug.ts")
         ↓
10. Permission Check: ✓ Approved
         ↓
11. Execute: Read file contents
         ↓
12. Codex: "Found the issue! Here's the fix..."
         ↓
13. @agentclientprotocol/sdk: Receive response
         ↓
14. OpenClaw Gateway: Format for Discord
         ↓
15. Discord: Show agent's response to user
```

## 💡 Common Questions Answered

### Q: Why use ACP instead of direct integration?

**A:** ACP standardizes communication. Instead of writing custom code for each agent, OpenClaw implements ACP once and works with all ACP-compatible agents.

### Q: How does session persistence work?

**A:** Sessions are stored as JSONL files in `~/.openclaw/agents/<agentId>/sessions/<sessionId>.jsonl`. The binding manager maps conversations to session keys deterministically.

### Q: Can I use this to build my own agent system?

**A:** Yes! The POC examples show the minimal implementation. For production:

1. Install `@agentclientprotocol/sdk`
2. Implement the `AcpRuntime` interface
3. Create a binding manager
4. Wire up your messaging channels
5. Handle tool permissions

See Example 4's README for detailed steps.

### Q: What's the difference between Example code and real OpenClaw?

**Examples:**
- Simplified for learning
- Mock data and tools
- In-memory state

**Real OpenClaw:**
- Production-grade error handling
- Persistent storage (JSONL files)
- Real tool execution
- Multiple backend support (Codex, Claude, Gemini)
- Security/sandboxing
- Rate limiting
- OAuth/auth integration

### Q: How do I debug ACP issues?

1. **Enable verbose logging** in your ACP runtime
2. **Check protocol messages** (newline-delimited JSON)
3. **Verify session keys** are being mapped correctly
4. **Test tool permissions** in isolation
5. **Look at OpenClaw logs** (`~/.openclaw/logs/`)

## 🛠️ Building Your Own Implementation

### Minimal Setup

```bash
npm install @agentclientprotocol/sdk
```

```javascript
import { ClientSideConnection, ndJsonStream } from '@agentclientprotocol/sdk';

// 1. Spawn an agent process
const proc = spawn('codex', [], { stdio: ['pipe', 'pipe', 'inherit'] });

// 2. Create stream
const stream = ndJsonStream(
  Writable.toWeb(proc.stdin),
  Readable.toWeb(proc.stdout)
);

// 3. Connect
const connection = new ClientSideConnection(() => ({
  agent: { name: 'my-app', version: '1.0.0' },
  
  async requestPermission(params) {
    // Your permission logic
    return { allowed: true };
  },
  
  async sessionUpdate(notification) {
    // Handle session updates
    console.log(notification);
  }
}), stream);

// 4. Use the connection
await connection.request('session/new', { mode: 'persistent' });
await connection.request('session/prompt', { text: 'Hello' });
```

### Production Checklist

- [ ] Session persistence (JSONL or database)
- [ ] Binding configuration (persistent + dynamic)
- [ ] Tool permission system
- [ ] Error handling and retries
- [ ] Rate limiting
- [ ] Logging/metrics
- [ ] Security (sandboxing, path validation)
- [ ] Graceful shutdown
- [ ] Process monitoring
- [ ] Testing

## 📖 Further Reading

### OpenClaw Docs
- [ACP Agents](../docs/tools/acp-agents.md)
- [Agent Loop](../docs/concepts/agent-loop.md)
- [Session Management](../docs/concepts/session.md)

### ACP Specification
- [Official Spec](https://agentclientprotocol.com/)
- [SDK GitHub](https://github.com/agentclientprotocol/sdk)

### OpenClaw Source
- Server: [src/acp/server.ts](../src/acp/server.ts)
- Client: [src/acp/client.ts](../src/acp/client.ts)
- Translator: [src/acp/translator.ts](../src/acp/translator.ts)
- Runtime: [src/acp/runtime/types.ts](../src/acp/runtime/types.ts)

## 🎉 You're Ready!

You now understand:

✅ What ACP is and why it matters
✅ How sessions and bindings work
✅ How agents use tools
✅ How @agentclientprotocol/sdk is integrated
✅ How to implement ACP in your own project

**Next Steps:**

1. Run all 4 examples
2. Read the real OpenClaw implementation
3. Try modifying the examples
4. Build your own integration!

---

**Questions or Issues?** 

Check the OpenClaw docs or look at the real implementation in `src/acp/`.

**Happy coding!** 🦞
