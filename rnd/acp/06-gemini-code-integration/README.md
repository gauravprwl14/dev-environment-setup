# Example 6: Real Gemini CLI Integration

📚 **[Quickstart →](./QUICKSTART.md)**

---

## How OpenClaw Uses Gemini

From OpenClaw's source ([`extensions/acpx/src/runtime-internals/mcp-agent-command.ts`](../../extensions/acpx/src/runtime-internals/mcp-agent-command.ts)):

```typescript
const ACPX_BUILTIN_AGENT_COMMANDS = {
  claude: "npx -y @zed-industries/claude-agent-acp",
  codex: "npx @zed-industries/codex-acp",
  gemini: "gemini",  // ← native ACP, no wrapper!
  opencode: "npx -y opencode-ai acp",
  pi: "npx pi-acp",
};
```

**Key difference from Claude:** The Gemini CLI (`gemini`) speaks ACP protocol natively. There is no separate ACP wrapper — you spawn the `gemini` binary directly. OpenClaw does exactly that.

## Key Difference vs Claude Integration

| | Claude (Example 05) | Gemini (Example 06) |
|---|---|---|
| Command | `npx -y @agentclientprotocol/claude-agent-acp` | `gemini` |
| ACP support | Via wrapper package | Native in CLI |
| Install | Auto via npx | `npm install -g @google/gemini-cli` |
| API key env | `ANTHROPIC_API_KEY` | `GEMINI_API_KEY` |
| Auth source | Anthropic Console | Google AI Studio |

## Package

```
@google/gemini-cli
```

- GitHub: https://github.com/google-gemini/gemini-cli
- npm: https://www.npmjs.com/package/@google/gemini-cli

Install globally (recommended, matches OpenClaw's `"gemini"` command):

```bash
npm install -g @google/gemini-cli
```

Or use npx (auto-downloads; the scripts handle this automatically as a fallback):

```bash
npx @google/gemini-cli
```

## Prerequisites

### 1. Install dependencies

```bash
cd 06-gemini-code-integration
npm install
```

### 2. Install Gemini CLI

```bash
npm install -g @google/gemini-cli
```

> Scripts automatically fall back to `npx @google/gemini-cli` if `gemini` is not on PATH.

### 3. Authentication

Set your API key:

```bash
export GEMINI_API_KEY="your-api-key"
```

Get a free key at: https://aistudio.google.com/apikey

## Running the Examples

### Test Connection

```bash
npm test
```

Runs 6 checks:
1. Gemini CLI availability (global or npx fallback)
2. `GEMINI_API_KEY` presence
3. Process spawn + stream setup
4. ACP protocol initialization
5. Session creation
6. Prompt round-trip

### Demo Script

```bash
npm start
```

Connects to Gemini, sends a prompt, and shows streaming output.

### Interactive Chat (Recommended)

```bash
npm run chat
```

**Commands:**
- `/exit` or `/quit` — Exit
- `/help` — Show commands
- `/clear` — Clear screen
- `Ctrl+C` — Exit gracefully

## What Happens Under the Hood

### 1. Resolve command

```javascript
// Prefer global install (matches OpenClaw), fall back to npx
let command, args;
try {
  execSync('gemini --version', { stdio: 'pipe' });
  command = 'gemini';
  args = ['--acp'];  // Required! Without this, Gemini starts its interactive TUI and hangs
} catch {
  command = 'npx';
  args = ['-y', '@google/gemini-cli', '--acp'];
}
```

### 2. Spawn process

```javascript
// command = 'gemini', args = ['--acp']
spawn(command, args, {
  stdio: ['pipe', 'pipe', 'inherit'],
  env: { ...process.env, GEMINI_API_KEY: process.env.GEMINI_API_KEY }
});
```

### 3. ACP protocol (identical to all other agents)

```javascript
const stream = ndJsonStream(
  Writable.toWeb(proc.stdin),
  Readable.toWeb(proc.stdout)
);

const client = new ClientSideConnection(() => ({
  sessionUpdate: async (notification) => { /* stream chunks */ },
  requestPermission: async (params) => { /* approve/deny tools */ }
}), stream);

await client.initialize({ protocolVersion: PROTOCOL_VERSION, ... });
const session = await client.newSession({ cwd, mcpServers: [] });
await client.prompt({ sessionId: session.sessionId, prompt: [{ type: 'text', text }] });
```

The ACP SDK handles all JSON-RPC framing automatically.

## Streaming Response Events

```javascript
switch (update.sessionUpdate) {
  case 'agent_message_chunk':
    process.stdout.write(update.content.text);   // live text stream
    break;
  case 'agent_thought_chunk':
    // Gemini thinking (if thinking mode is on)
    break;
  case 'tool_call':
    console.log(`Tool: ${update.title}`);
    break;
  case 'tool_call_update':
    // success / error
    break;
  case 'plan':
    // Gemini's reasoning plan
    break;
}
```

## How This Relates to OpenClaw

| This Example | OpenClaw Implementation |
|---|---|
| `spawn('gemini', [], ...)` | `spawn(command, args, ...)` where `command = "gemini"` |
| `ClientSideConnection` | `ClientSideConnection` |
| `ndJsonStream` | `ndJsonStream` |
| `sessionUpdate` handler | `printSessionUpdate()` |
| `requestPermission` handler | `resolvePermissionRequest()` |

The pattern is **identical** across Claude, Codex, Gemini, and every other ACP agent — only the spawn command changes.

## Troubleshooting

### `gemini: command not found`

Install globally:

```bash
npm install -g @google/gemini-cli
```

Or the scripts will use `npx @google/gemini-cli` automatically.

### Authentication errors (401 / 403)

```bash
export GEMINI_API_KEY="your-api-key"
# Get key from: https://aistudio.google.com/apikey
```

### Prompt timeout

The CLI may be slow on first run (downloading model data). Increase the timeout or wait longer before retrying.

### `npx: command not found`

```bash
brew install node   # macOS
# or download from nodejs.org
```

## ACP Protocol Wire Format

Same JSON-RPC 2.0 over nd-JSON as every other ACP agent:

```
→ {"jsonrpc":"2.0","method":"session/initialize","params":{...},"id":1}
← {"jsonrpc":"2.0","result":{...},"id":1}

→ {"jsonrpc":"2.0","method":"session/new","params":{...},"id":2}
← {"jsonrpc":"2.0","result":{"sessionId":"sess_abc"},"id":2}

→ {"jsonrpc":"2.0","method":"session/prompt","params":{"sessionId":"sess_abc","prompt":[...]},"id":3}
← {"jsonrpc":"2.0","method":"session/notification","params":{"update":{...}}}
← {"jsonrpc":"2.0","result":{"stopReason":"end_turn"},"id":3}
```

## Key Takeaways

1. **Native ACP** — Gemini CLI speaks ACP directly, no wrapper needed
2. **Same SDK** — `@agentclientprotocol/sdk` works identically for all agents
3. **Same pattern** — Spawn → Connect → Initialize → Session → Prompt → Stream
4. **OpenClaw-aligned** — `gemini` command matches `ACPX_BUILTIN_AGENT_COMMANDS.gemini`

---

🔗 [← Back to Main POC](../README.md) | [05 - Claude Integration](../05-claude-code-integration/README.md)
