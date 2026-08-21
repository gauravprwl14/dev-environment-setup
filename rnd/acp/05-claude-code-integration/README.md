# Example 5: Real Claude Code Integration

📚 **[Complete Knowledge Transfer Documentation →](./KNOWLEDGE-TRANSFER.md)**  
*Comprehensive guide with architecture diagrams, code walkthroughs, and best practices*

---

## ⚠️ CRITICAL: Standard Claude CLI Does NOT Work!

The standard `claude` CLI **DOES NOT** speak ACP protocol. OpenClaw uses a special wrapper.

## What OpenClaw Actually Uses

From OpenClaw's source code ([`extensions/acpx/src/runtime-internals/mcp-agent-command.ts`](../../extensions/acpx/src/runtime-internals/mcp-agent-command.ts)):

```typescript
const ACPX_BUILTIN_AGENT_COMMANDS = {
  claude: "npx -y @zed-industries/claude-agent-acp",  // ← ACP wrapper, NOT standard CLI!
  // ...
};
```

### 📦 Package Migration Note

**UPDATE (March 2026):** These packages have been renamed:
- ~~`@zed-industries/claude-agent-acp`~~ → `@agentclientprotocol/claude-agent-acp`
- ~~`@zed-industries/codex-acp`~~ → `@agentclientprotocol/codex-acp`

Both old and new names currently work, but the old names show deprecation warnings. **This POC uses the new package names.** OpenClaw's source code may still reference the old names but will likely be updated soon.

## What This Example Shows

This is a **real, working integration** with the ACP-compatible Claude wrapper using the actual `@agentclientprotocol/sdk` package. This is not a mock or simulation - it's what OpenClaw actually uses in production!

## Prerequisites

### 1. Install Dependencies

```bash
cd 05-claude-code-integration
npm install
```

This installs `@agentclientprotocol/sdk` - the same package OpenClaw uses.

### 2. ~~No Manual Installation Required!~~

**You do NOT need to install `claude` CLI manually.**

The test uses `npx -y @agentclientprotocol/claude-agent-acp`, which:
- Downloads automatically on first run
- Is the **actual ACP-compatible wrapper**
- Uses the new package name (old `@zed-industries/...` is deprecated)

### 3. Authentication

The `@agentclientprotocol/claude-agent-acp` wrapper handles authentication. If prompted, you may need:
- An Anthropic API key (`ANTHROPIC_API_KEY` environment variable)
- Or OAuth token (check wrapper documentation)

## Running the Examples

### 🧪 Test Connection (Quickest)

Test that everything is working:

```bash
npm test
```

Runs through 5 quick tests to verify:
- ACP wrapper can be spawned
- Protocol initializes
- Session can be created
- Prompts work correctly

### 🎯 Demo Script

Run the demo with pre-defined examples:

```bash
npm start
```

Shows how to:
- Connect to Claude
- Send prompts
- Handle streaming responses
- Manage tool permissions

### 💬 Interactive Chat (Recommended!)

Start a continuous conversation with Claude:

```bash
npm run chat
```

**Features:**
- Continuous back-and-forth conversation
- Real-time streaming responses
- Maintains conversation context
- Just like using Claude Code or OpenClaw!

**Commands while chatting:**
- `/exit` or `/quit` - Exit the chat
- `/help` - Show available commands
- `/clear` - Clear the screen
- `Ctrl+C` - Exit gracefully

**Example session:**
```
You: What is the capital of France?

Claude: The capital of France is Paris. It has been the capital 
since 987 AD and is located in the north-central part of the country...

You: What's its population?

Claude: Paris has a population of approximately 2.1 million people
within the city limits, and about 12 million in the greater Paris
metropolitan area...

You: /exit

👋 Goodbye!
```

## What Happens

The example demonstrates a complete Claude Code integration:

### 1. Process Spawning
```javascript
spawn('npx', ['-y', '@agentclientprotocol/claude-agent-acp'], {
  stdio: ['pipe', 'pipe', 'inherit'],
  cwd,
  env: { ...process.env }
});
```

Uses Node's `child_process.spawn` to start the **ACP-compatible Claude wrapper** (NOT standard `claude` CLI) as a subprocess.

**Important:** 
- Standard `claude` CLI does not speak ACP protocol!
- Old package: `@zed-industries/claude-agent-acp` (deprecated)
- New package: `@agentclientprotocol/claude-agent-acp` (use this)

### 2. ACP Protocol Setup
```javascript
const input = Writable.toWeb(process.stdin);
const output = Readable.toWeb(process.stdout);
const stream = ndJsonStream(input, output);
```

Creates bidirectional streams for JSON-RPC communication over newline-delimited JSON.

### 3. Client Connection
```javascript
const client = new ClientSideConnection(
  () => ({
    sessionUpdate: async (notification) => {
      // Handle streaming responses
    },
    requestPermission: async (params) => {
      // Handle tool permission requests
    }
  }),
  stream
);
```

The SDK's `ClientSideConnection` handles the protocol automatically.

### 4. Protocol Handshake
```javascript
await client.initialize({
  protocolVersion: PROTOCOL_VERSION,
  clientCapabilities: {
    fs: { readTextFile: true, writeTextFile: true },
    terminal: true,
  },
  clientInfo: { name: 'openclaw-claude-demo', version: '1.0.0' }
});
```

Negotiates capabilities with Claude Code.

### 5. Session Creation
```javascript
const session = await client.newSession({
  cwd,
  mcpServers: []
});
```

Creates a persistent conversation session.

### 6. Sending Prompts
```javascript
await client.prompt({
  sessionId: session.sessionId,
  text: 'What is the capital of France?'
});
```

Sends messages to Claude and receives streaming responses.

## SDK Features Demonstrated

### ClientSideConnection

The main class for acting as an ACP client:

- **`initialize()`** - Protocol handshake
- **`newSession()`** - Create conversation session
- **`prompt()`** - Send message to agent
- **`listSessions()`** - Get active sessions
- **`loadSession()`** - Resume previous session
- **`setSessionMode()`** - Change session settings

### Session Updates (Streaming)

Claude Code sends real-time updates:

```javascript
sessionUpdate: async (notification) => {
  switch (notification.update.sessionUpdate) {
    case 'agent_message_chunk':
      // Text streaming (Claude typing)
      process.stdout.write(notification.update.content.text);
      break;
      
    case 'tool_call':
      // Claude using a tool (read file, run command)
      console.log(`Tool: ${notification.update.title}`);
      break;
      
    case 'plan':
      // Claude's plan for solving the task
      console.log(`Plan: ${notification.update.content.text}`);
      break;
  }
}
```

### Permission Requests

Claude Code asks permission before using tools:

```javascript
requestPermission: async (params) => {
  const toolTitle = params.toolCall?.title;
  const options = params.options;
  
  // Auto-approve safe tools
  if (isSafeTool(toolTitle)) {
    return { outcome: { outcome: 'selected', optionId: allowOption.optionId } };
  }
  
  // Prompt user for others
  const approved = await askUser(`Allow ${toolTitle}?`);
  return approved ? allowOutcome : denyOutcome;
}
```

## Example Output

```
🚀 Connecting to Claude Code CLI...

📝 Spawning: npx -y @agentclientprotocol/claude-agent-acp
✅ Streams created
✅ Client connection created

🔌 Initializing ACP protocol...
✅ Initialized with protocol version: 0.1.0

📝 Creating new Claude Code session...
✅ Session created: sess_abc123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Ready to interact with Claude Code!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💬 You: What is the capital of France?

🤔 Claude is thinking...

The capital of France is Paris. It has been the capital since 987 AD...

✅ Response received
   Stop reason: end_turn

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💬 You: Can you list files in the current directory?

🤔 Claude is thinking...

🔧 Tool: read_file: package.json
📋 Plan: I'll use the list_directory tool to show you the files
🔧 Tool: list_directory: .
✅ Tool completed

Here are the files in the current directory:
- claude-code-real.js
- package.json
- README.md
- test-connection.js

✅ Response received
   Stop reason: end_turn
```

## How This Relates to OpenClaw

This example uses **exactly the same pattern** as OpenClaw's `src/acp/client.ts`:

| This Example | OpenClaw Implementation |
|-------------|------------------------|
| `spawn('npx', ['-y', '@zed-industries/claude-agent-acp'], ...)` | `spawn(command, args, ...)` where command is from `ACPX_BUILTIN_AGENT_COMMANDS` |
| `ClientSideConnection` | `ClientSideConnection` |
| `ndJsonStream` | `ndJsonStream` |
| `sessionUpdate` handler | `printSessionUpdate()` |
| `requestPermission` handler | `resolvePermissionRequest()` |

The only differences:
- OpenClaw supports multiple agents (Codex, Claude, Gemini)
- OpenClaw has more sophisticated permission logic
- OpenClaw integrates with gateway/bindings system
- OpenClaw persists sessions to disk

**This example IS the core of how OpenClaw works!**

## Advanced Usage

### Reusable Client Class

```javascript
import { ClaudeCodeClient } from './claude-code-real.js';

const client = new ClaudeCodeClient();

await client.connect({ cwd: '/path/to/project' });

await client.sendPrompt('Analyze this codebase and summarize the architecture');

await client.close();
```

### Multiple Sessions

```javascript
// Create multiple independent sessions
const session1 = await client.client.newSession({ cwd: '/project1' });
const session2 = await client.client.newSession({ cwd: '/project2' });

// Send prompts to different sessions
await client.client.prompt({
  sessionId: session1.sessionId,
  text: 'Fix bugs in project 1'
});

await client.client.prompt({
  sessionId: session2.sessionId,
  text: 'Add tests to project 2'
});
```

### Resume Previous Session

```javascript
// Store session ID
const sessionId = 'sess_previous';

// Later, load history
await client.client.loadSession({ sessionId });

// Continue where you left off
await client.client.prompt({
  sessionId,
  text: 'Continue where we left off'
});
```

## Troubleshooting

### Test hangs at "Testing protocol initialization..."

**Problem:** Standard `claude` CLI doesn't speak ACP protocol. It waits for interactive input.

**Solution:** The test now uses the correct command:
```javascript
spawn('npx', ['-y', '@zed-industries/claude-agent-acp'], ...)
```

This is what OpenClaw uses in production!

### "npx: command not found"

**Solution:** Install Node.js, which includes npm and npx:
```bash
# macOS
brew install node

# Or download from nodejs.org
# Add /bin to your PATH
```

### "Authentication required"

**Solution:** The `@agentclientprotocol/claude-agent-acp` wrapper handles authentication internally. If prompted, you may need to set:

```bash
export ANTHROPIC_API_KEY="your-api-key"
```

Get your API key from: https://console.anthropic.com/

### "Connection timeout"

The ACP wrapper may be slow to start on first run (especially if downloading). Wait a bit longer or check:

```bash
# Test if npx works
npx -y @agentclientprotocol/claude-agent-acp --help
```

### Permission denied errors

If Claude can't access files:
- Check file permissions
- Ensure cwd is correct
- Make sure Claude has read/write access

## Protocol Details

The ACP protocol used here is **JSON-RPC 2.0 over newline-delimited JSON (nd-JSON)**:

```json
→ {"jsonrpc":"2.0","method":"session/initialize","params":{...},"id":1}
← {"jsonrpc":"2.0","result":{...},"id":1}

→ {"jsonrpc":"2.0","method":"session/new","params":{...},"id":2}
← {"jsonrpc":"2.0","result":{"sessionId":"sess_abc"},"id":2}

→ {"jsonrpc":"2.0","method":"session/prompt","params":{"sessionId":"sess_abc","text":"..."},"id":3}
← {"jsonrpc":"2.0","method":"session/notification","params":{"update":{...}}}
← {"jsonrpc":"2.0","method":"session/notification","params":{"update":{...}}}
← {"jsonrpc":"2.0","result":{"text":"...","stopReason":"end_turn"},"id":3}
```

The SDK handles all of this automatically!

## Security Notes

- Claude Code runs with your user permissions
- Tool calls require explicit approval
- You can see all tool activity in real-time
- Session data is stored locally by Claude

## Key Takeaways

1. **Real SDK Integration** - This uses the actual `@agentclientprotocol/sdk` package
2. **Production Pattern** - Same code structure as OpenClaw
3. **Complete Flow** - Spawn → Connect → Initialize → Session → Prompt → Stream
4. **Permission System** - Interactive tool approval
5. **Streaming Responses** - Real-time Claude output

## ⚠️ IMPORTANT: Standard Claude CLI vs ACP Wrapper

### What Does NOT Work

```bash
# ❌ WRONG - Standard Claude CLI (interactive only)
spawn('claude', [], ...)
```

The standard `claude` CLI from Anthropic:
- Is for **interactive** use only
- Does **NOT** speak ACP protocol
- Will hang waiting for input
- Cannot be programmatically controlled

### What DOES Work ✅

```bash
# ✅ CORRECT - ACP-compatible wrapper (NEW package name)
spawn('npx', ['-y', '@agentclientprotocol/claude-agent-acp'], ...)
```

The `@agentclientprotocol/claude-agent-acp` package:
- Speaks **ACP protocol** (JSON-RPC over nd-JSON)
- Can be **spawned programmatically**
- Supports **bidirectional communication**
- Is the **new name** for the deprecated `@zed-industries/claude-agent-acp`

### All ACP-Compatible Commands

From OpenClaw's [`extensions/acpx/src/runtime-internals/mcp-agent-command.ts`](../../extensions/acpx/src/runtime-internals/mcp-agent-command.ts):

```typescript
// OpenClaw's current config (may still use old package names):
const ACPX_BUILTIN_AGENT_COMMANDS = {
  claude: "npx -y @zed-industries/claude-agent-acp",  // Deprecated
  codex: "npx @zed-industries/codex-acp",            // Deprecated
  gemini: "gemini",
  opencode: "npx -y opencode-ai acp",
  pi: "npx pi-acp",
};

// Recommended (new package names):
const RECOMMENDED_COMMANDS = {
  claude: "npx -y @agentclientprotocol/claude-agent-acp",
  codex: "npx @agentclientprotocol/codex-acp",
  gemini: "gemini",
  opencode: "npx -y opencode-ai acp",
  pi: "npx pi-acp",
};
```

### Why This Matters

If you try to use the standard `claude` CLI:
1. Your code will hang at initialization
2. The agent will wait for keyboard input
3. No ACP messages will be exchanged
4. You won't get any error messages

**Always use the ACP-compatible wrappers!**

## Next Steps

- Try modifying the prompts
- Add your own tool permission logic
- Integrate with other systems
- Build a UI around this
- Support multiple agents (Codex, Gemini)

---

🔗 [← Back to Main POC](../README.md) | [OpenClaw ACP Client](../../src/acp/client.ts)

**You now have a real, working Claude Code integration!** 🎉
