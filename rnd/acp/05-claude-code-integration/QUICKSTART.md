# Quick Start: Interactive Chat with Claude

Get started chatting with Claude via ACP in 3 simple steps!

## 1. Set Your API Key

Get your Anthropic API key from: https://console.anthropic.com/

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Pro tip:** Add this to your `~/.zshrc` or `~/.bashrc` to make it permanent:
```bash
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
source ~/.zshrc
```

## 2. Install Dependencies (One Time)

```bash
cd 05-claude-code-integration
npm install
```

This installs `@agentclientprotocol/sdk` - the same SDK OpenClaw uses.

## 3. Start Chatting!

```bash
npm run chat
```

That's it! You'll see:

```
╔════════════════════════════════════════════════════════════════════════════╗
║                   Interactive Chat with Claude via ACP                     ║
╚════════════════════════════════════════════════════════════════════════════╝

Commands: /exit, /quit, /help, /clear

🔌 Connecting to Claude... ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 Ready to chat! Type your message and press Enter.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You: 
```

## What to Try

### Simple Questions
```
You: What is the capital of France?
```

### Code Help
```
You: Write a JavaScript function to sort an array
```

### File Operations
```
You: What files are in the current directory?
```

### Continuing Conversations
```
You: What is React?

Claude: React is a JavaScript library...

You: Can you give me an example?

Claude: Sure! Here's a simple example...
```

The conversation context is maintained throughout the session!

## Features

### ✅ Streaming Responses
Claude's responses appear in real-time as they're generated, just like in Claude Code.

### ✅ Tool Support
Claude can use tools like `read_file`, `list_directory`, etc. 

**Safe operations (auto-approved):**
- Reading files
- Listing directories
- Searching files

**Potentially dangerous operations (requires confirmation):**
- Writing files
- Running commands
- Deleting files

Example:
```
You: Read the package.json file

🔧 Using tool: read_file
✅ Tool completed

Claude: I can see from the package.json that...
```

### ✅ Conversation Context
Each session maintains full conversation history. Claude remembers what you talked about earlier in the conversation.

## Commands

While chatting, you can use these commands:

| Command | Description |
|---------|-------------|
| `/exit`, `/quit` | Exit the chat |
| `/help` | Show available commands |
| `/clear` | Clear the screen |
| `Ctrl+C` | Exit gracefully (same as /exit) |

## Troubleshooting

### "ANTHROPIC_API_KEY environment variable not set"

**Solution:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
npm run chat
```

### Connection is slow on first run

**Why:** The ACP wrapper (`@agentclientprotocol/claude-agent-acp`) is being downloaded via npx.

**Solution:** Just wait ~10-30 seconds on first run. Subsequent runs are instant.

### "Error: Invalid params"

**Why:** You might be using an outdated version of the SDK.

**Solution:**
```bash
rm -rf node_modules package-lock.json
npm install
npm run chat
```

### Connection timeout

**Why:** Network issue or API key problem.

**Solution:**
1. Check your internet connection
2. Verify your API key is valid: https://console.anthropic.com/
3. Try again in a few seconds

## How It Works

This interactive chat:

1. **Spawns** the ACP-compatible Claude wrapper: `@agentclientprotocol/claude-agent-acp`
2. **Connects** via the `@agentclientprotocol/sdk`
3. **Creates** a persistent session
4. **Maintains** conversation context across all messages
5. **Streams** responses in real-time as Claude generates them

**It's exactly how OpenClaw and Claude Code work internally!**

See the code: [`interactive-chat.js`](./interactive-chat.js)

## What's Different from Claude Code?

| Feature | Claude Code | This Example | Notes |
|---------|-------------|--------------|-------|
| Streaming | ✅ | ✅ | Same |
| Tool permissions | ✅ | ✅ | Same |
| Conversation context | ✅ | ✅ | Same |
| Syntax highlighting | ✅ | ❌ | Terminal limitation |
| File browser | ✅ | ❌ | Could be added |
| Rich UI | ✅ | ❌ | Terminal limitation |

The **core ACP integration is identical** - this is a minimal terminal version showing the same underlying protocol.

## Next Steps

### Add More Features

The `InteractiveChatClient` class in `interactive-chat.js` is easy to extend:

**Add command history:**
```javascript
// Use readline's history feature
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  history: previousMessages  // Array of previous inputs
});
```

**Save conversation:**
```javascript
const fs = require('fs');
fs.writeFileSync('conversation.json', JSON.stringify(messages));
```

**Add syntax highlighting:**
```javascript
import chalk from 'chalk';
// Color code blocks, keywords, etc.
```

### Use It as a Library

Import the client in your own code:

```javascript
import { InteractiveChatClient } from './interactive-chat.js';

const client = new InteractiveChatClient();
await client.connect();

const response = await client.sendMessage('Hello!');
console.log(response);

client.close();
```

### Study OpenClaw's Implementation

Compare this with OpenClaw's actual implementation:
- Server: [`src/acp/server.ts`](../../src/acp/server.ts)
- Client: [`src/acp/client.ts`](../../src/acp/client.ts)
- Translator: [`src/acp/translator.ts`](../../src/acp/translator.ts)

You'll see the same core patterns!

## Questions?

Check out:
- [Main README](./README.md) - Full documentation
- [SDK Integration Guide](../SDK-INTEGRATION.md) - Deep dive into the SDK
- [OpenClaw Documentation](https://docs.openclaw.ai/) - Production implementation

---

**Happy chatting! 🎉**
