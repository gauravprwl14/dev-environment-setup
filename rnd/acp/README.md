# ACP (Agent Client Protocol) - Beginner's Guide

This POC demonstrates how OpenClaw uses the Agent Client Protocol (ACP) to connect agents, sessions, channels, and tool calls in a practical way.

## 🎉 Now With Real SDK Integration!

All examples now include the **actual `@agentclientprotocol/sdk`** package used by OpenClaw! You can run both:
- **Simplified examples** - No dependencies, learn concepts
- **Real SDK examples** - See actual SDK usage

**[📦 Installation Guide →](./INSTALL-SDK.md)**

## 📚 What You'll Learn

1. **What is ACP?** - The protocol that lets different agents communicate
2. **How agents and sessions work** - Managing conversation state
3. **Channel & thread bindings** - Routing messages to the right place
4. **Tool calls** - How agents execute actions
5. **Message flow** - End-to-end message delivery

## 🎯 Core Concepts Explained Simply

### 1. ACP (Agent Client Protocol)

**What it is:** A standardized way for coding assistants (like Claude, Codex, Gemini CLI) to communicate with OpenClaw.

**Think of it like:** A phone protocol - just like you can call anyone's phone regardless of carrier, ACP lets any agent talk to OpenClaw regardless of who built it.

**Real example:**
```
User sends message in Discord → OpenClaw receives it → Routes to an ACP agent (Codex) → Codex responds → OpenClaw sends reply back to Discord
```

### 2. Sessions

**What it is:** A conversation container that holds all messages and context.

**Think of it like:** An email thread - it keeps all related messages together.

**Key concepts:**
- **SessionKey**: Unique identifier like `agent:main:acp:discord:123abc`
- **SessionId**: Internal UUID for storage
- **Session Store**: Where conversation history is kept

**Real example:**
```typescript
// When you message your agent on Discord
{
  sessionKey: "agent:main:acp:discord:channelId:hash",
  messages: [
    { role: "user", content: "Write a function to sort arrays" },
    { role: "assistant", content: "Here's the implementation..." }
  ]
}
```

### 3. Channel & Thread Bindings

**What it is:** The mapping system that connects messaging channels (Discord, Telegram, etc.) to specific agent sessions.

**Think of it like:** Call forwarding - when someone calls your work phone, it knows to forward to your agent.

**Types of bindings:**

#### A. **Persistent Bindings** (configured in config file)
```json
{
  "bindings": [{
    "type": "acp",
    "match": {
      "channel": "discord",
      "peer": { "id": "channel-123" }
    },
    "agentId": "main",
    "acp": {
      "mode": "persistent",
      "backend": "codex"
    }
  }]
}
```

This says: "All messages from Discord channel-123 should go to a persistent Codex ACP session"

#### B. **Dynamic Bindings** (created on-the-fly)
```typescript
// User says: "Start a Codex session in this thread"
{
  conversation: {
    channel: "telegram",
    conversationId: "topic-456"
  },
  targetSessionKey: "agent:main:acp:telegram:topic-456:xyz",
  status: "active"
}
```

### 4. Tool Calls

**What it is:** Actions the agent can perform (read files, run commands, search, etc.)

**Think of it like:** Apps on your phone - each tool is like an app the agent can open and use.

**Real example:**
```typescript
// Agent wants to read a file
{
  type: "tool_call",
  toolName: "read_file",
  input: {
    path: "/Users/you/project/src/main.ts",
    startLine: 1,
    endLine: 50
  }
}

// OpenClaw executes it and returns result
{
  type: "tool_result",
  content: "import express from 'express'...",
  success: true
}
```

### 5. Message Flow (End-to-End)

```
┌─────────────┐
│   Discord   │ User sends: "Fix the bug in auth.ts"
│   Channel   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│  OpenClaw Gateway (WebSocket Server)             │
│  - Receives message from Discord                │
│  - Looks up binding for this channel            │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│  Session Binding Manager                        │
│  - Finds: channel:discord → session:acp:xyz     │
│  - Retrieves conversation history               │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│  ACP Runtime Manager                            │
│  - Ensures ACP session exists                   │
│  - Sends prompt to Codex/Claude via ACP         │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│  Codex/Claude (External Agent)                  │
│  - Reads auth.ts                                │
│  - Analyzes the bug                             │
│  - Makes tool calls (read_file, write_file)     │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│  ACP Gateway Translator                         │
│  - Receives agent response stream               │
│  - Translates ACP events to OpenClaw events     │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│  OpenClaw Gateway                               │
│  - Formats response for Discord                 │
│  - Sends message back to channel                │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────┐
│   Discord   │ Agent replies: "Fixed! Here's what I changed..."
│   Channel   │
└─────────────┘
```

## 🔧 Practical Examples

### Example 1: Simple Message Flow
See: [01-simple-message-flow/](./01-simple-message-flow/)

### Example 2: Channel Binding
See: [02-channel-binding/](./02-channel-binding/)

### Example 3: Tool Calls
See: [03-tool-calls/](./03-tool-calls/)

### Example 4: Complete Integration
See: [04-complete-integration/](./04-complete-integration/)

### Example 5: Real Claude Code Integration ⭐ NEW!
See: [05-claude-code-integration/](./05-claude-code-integration/)

**Features:**
- 🎯 Uses the actual `@agentclientprotocol/sdk` package
- 💬 **Interactive chat mode** - Continuous conversation with Claude
- 🔄 Streaming responses in real-time
- 🛠️ Tool permission handling
- 📝 Maintains conversation context

**Three ways to use it:**
1. `npm test` - Quick connection test
2. `npm start` - Demo with examples
3. `npm run chat` - **Interactive chat (recommended!)**

**Quick start:**
```bash
cd 05-claude-code-integration
export ANTHROPIC_API_KEY="sk-ant-..."
npm install
npm run chat
```

[📖 Quick Start Guide](./05-claude-code-integration/QUICKSTART.md)  
[📚 Complete Knowledge Transfer Doc](./05-claude-code-integration/KNOWLEDGE-TRANSFER.md)

## 🚀 Quick Start

Each example folder contains:
- `README.md` - Detailed explanation
- Working code examples
- Comments explaining each step
- How to run and test

Start with Example 1 and work your way up!

## 📖 Key Files in OpenClaw

If you want to see the real implementation:

- **ACP Server**: `src/acp/server.ts` - Main ACP gateway server
- **ACP Client**: `src/acp/client.ts` - Client that connects to external agents
- **Session Manager**: `src/acp/control-plane/manager.ts` - Manages ACP sessions
- **Bindings**: `src/acp/persistent-bindings.*.ts` - Channel/thread binding logic
- **Translator**: `src/acp/translator.ts` - Translates between ACP and OpenClaw events
- **Runtime Types**: `src/acp/runtime/types.ts` - Core type definitions

## 🎓 Learning Path

1. **Start here**: Read this README thoroughly
2. **Example 1**: Run the simple message flow example
3. **Example 2**: Understand channel bindings
4. **Example 3**: Learn session management
5. **Example 4**: Explore tool calls
6. **Example 5**: See it all work together
7. **Real code**: Look at the actual OpenClaw implementation

## 💡 Common Use Cases

### Use Case 1: Multi-Channel Agent
**Scenario**: You want one agent accessible from Discord, Telegram, and Slack

**Solution**: Configure persistent bindings for each channel:
```json
{
  "bindings": [
    { "channel": "discord", "peer": {"id": "channel-1"}, "acp": {...} },
    { "channel": "telegram", "peer": {"id": "chat-2"}, "acp": {...} },
    { "channel": "slack", "peer": {"id": "chan-3"}, "acp": {...} }
  ]
}
```

### Use Case 2: Per-Thread Agents
**Scenario**: Different Discord threads should use different agents

**Solution**: Use dynamic thread bindings with spawn:
```typescript
// In thread A: spawn Codex
// In thread B: spawn Claude
// Each thread maintains its own session
```

### Use Case 3: Tool Sandboxing
**Scenario**: Allow file reading but not execution in production

**Solution**: Configure tool policies at the ACP runtime level

## 🤔 FAQ

**Q: What's the difference between ACP and regular OpenClaw agents?**
A: ACP lets you use *external* agents (Codex, Claude Code, Gemini CLI) through a standard protocol. Regular OpenClaw agents are built-in.

**Q: Can I build my own ACP-compatible agent?**
A: Yes! Implement the ACP protocol spec and register your runtime backend.

**Q: How do sessions survive restarts?**
A: Sessions are stored as JSONL files in `~/.openclaw/agents/<agentId>/sessions/`

**Q: What happens if two users message the same channel?**
A: Depends on your `dmScope` config:
- `main`: Both share the same session (risky!)
- `per-channel-peer`: Each user gets their own session (recommended)

## 🛠️ Implementing ACP in Your Project

Want to add ACP to your own project? Here's the checklist:

1. **Install the SDK**: `npm install @agentclientprotocol/sdk`
2. **Implement AcpRuntime interface**: See `src/acp/runtime/types.ts`
3. **Register your runtime**: Use `registerAcpRuntimeBackend()`
4. **Handle events**: Listen for text_delta, tool_call, done, error
5. **Manage sessions**: Store conversation history
6. **Connect channels**: Map your messaging inputs to sessions

See [05-complete-integration/implementing-acp.md](./05-complete-integration/implementing-acp.md) for a step-by-step guide.

## 📚 Additional Resources

- [ACP Spec](https://agentclientprotocol.com/)
- [OpenClaw ACP Docs](../docs/tools/acp-agents.md)
- [Agent Loop Docs](../docs/concepts/agent-loop.md)
- [Session Management](../docs/concepts/session.md)

---

**Ready to dive in?** Start with [Example 1: Simple Message Flow](./01-simple-message-flow/)
