# ACP Protocol Integration - Complete Knowledge Transfer

> **Comprehensive guide to understanding and implementing the Agent Client Protocol (ACP) with real code examples**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Concepts](#core-concepts)
4. [Protocol Deep Dive](#protocol-deep-dive)
5. [Code Walkthrough](#code-walkthrough)
6. [Integration Patterns](#integration-patterns)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Overview

### What is ACP?

**Agent Client Protocol (ACP)** is a standardized communication protocol that enables AI coding assistants (agents) to interact with client applications in a consistent way, regardless of which AI service powers them.

```
┌─────────────────────────────────────────────────────────────┐
│  Think of ACP like USB:                                     │
│                                                              │
│  • USB = Universal Standard for Hardware                    │
│  • ACP = Universal Standard for AI Agents                   │
│                                                              │
│  Just like you can plug any USB device into any USB port,  │
│  you can connect any ACP-compatible agent to any ACP        │
│  client!                                                     │
└─────────────────────────────────────────────────────────────┘
```

### Why ACP Matters

**Without ACP:**
```
Your App ──custom API──→ Claude (Anthropic-specific API)
Your App ──custom API──→ GPT (OpenAI-specific API)
Your App ──custom API──→ Gemini (Google-specific API)

Problem: You need to write different code for each AI service!
```

**With ACP:**
```
Your App ──ACP Protocol──→ Claude Wrapper ──→ Anthropic API
         ──ACP Protocol──→ GPT Wrapper   ──→ OpenAI API
         ──ACP Protocol──→ Gemini Wrapper──→ Google API

Solution: Write once, works with all ACP-compatible agents!
```

---

## Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Your Application                            │
│  (interactive-chat.js, claude-code-real.js, OpenClaw, etc.)     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Uses @agentclientprotocol/sdk
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              @agentclientprotocol/sdk (npm package)              │
│                                                                  │
│  • ClientSideConnection - Connect to agents                     │
│  • ndJsonStream - Protocol stream handler                       │
│  • Type definitions - Full TypeScript support                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ ACP Protocol (JSON-RPC over nd-JSON)
                         │ via stdin/stdout pipes
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│           ACP Wrapper (Separate Process/Executable)             │
│                                                                  │
│  • @agentclientprotocol/claude-agent-acp (npx executable)      │
│  • @agentclientprotocol/codex-acp                              │
│  • opencode-ai acp                                              │
│                                                                  │
│  Handles:                                                        │
│  - Protocol translation (ACP ↔ Native API)                     │
│  - Authentication                                                │
│  - Rate limiting                                                 │
│  - Error handling                                                │
│  - Session management                                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTP/REST/gRPC
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AI Service APIs                               │
│                                                                  │
│  • Anthropic API (Claude)                                       │
│  • OpenAI API (GPT)                                             │
│  • Google AI (Gemini)                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Process Communication Model

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Host Process (Node.js)                         │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Your Application Code                                         │ │
│  │                                                                 │ │
│  │  const proc = spawn('npx', ['claude-agent-acp']);            │ │
│  │  const stream = ndJsonStream(proc.stdin, proc.stdout);        │ │
│  │  const client = new ClientSideConnection(..., stream);        │ │
│  └──────────────────────┬──────────────────────────────────────┬──┘ │
│                         │                                       │    │
│                     ┌───▼───┐                              ┌───▼───┐│
│                     │ stdin │                              │stdout ││
│                     │ pipe  │                              │ pipe  ││
│                     └───┬───┘                              └───▲───┘│
└─────────────────────────┼──────────────────────────────────────┼────┘
                          │                                       │
                      Write JSON                              Read JSON
                          │                                       │
                          ▼                                       │
┌──────────────────────────────────────────────────────────────────────┐
│                    Child Process (ACP Wrapper)                        │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  ACP Wrapper Implementation                                    │ │
│  │                                                                 │ │
│  │  1. Read JSON from stdin                                       │ │
│  │  2. Parse ACP request                                          │ │
│  │  3. Call native API (Anthropic/OpenAI/etc.)                   │ │
│  │  4. Format response as ACP JSON                                │ │
│  │  5. Write JSON to stdout ─────────────────────────────────────┤ │
│  └────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### 1. Sessions

**What is a Session?**
- A conversation container that holds all messages and context
- Like an email thread or chat conversation
- Maintains history across multiple messages

**Session Lifecycle:**
```
┌─────────┐     newSession()      ┌────────────┐
│ Client  │ ─────────────────────→ │  Session   │
└─────────┘                        │  Created   │
     │                             └────────────┘
     │                                    │
     │  prompt("Hello")                   │
     │ ─────────────────────────────────→ │
     │                                    │
     │ ← streaming response chunks ────── │
     │                                    │
     │  prompt("Continue...")             │
     │ ─────────────────────────────────→ │
     │                                    │ (Context maintained!)
     │ ← streaming response chunks ────── │
     │                                    │
     │  close()                           │
     │ ─────────────────────────────────→ │
     │                                    ▼
     │                             ┌────────────┐
     │                             │  Session   │
     │                             │  Closed    │
     └─────────────────────────────└────────────┘
```

**Session Properties:**
```javascript
{
  sessionId: "75ddb14b-975b-45e6-9058-4569844535de",  // UUID
  cwd: "/path/to/working/directory",                  // Working directory
  mcpServers: [],                                     // Model Context Protocol servers
  // Context is maintained internally by the wrapper
}
```

### 2. Streaming Updates

**Real-time Response Streaming:**

The ACP protocol streams responses in real-time, chunk by chunk, just like typing on a keyboard.

```
Time ───────────────────────────────────────────────→

User sends: "Explain React"

Claude response arrives as chunks:

Chunk 1:  "React"
Chunk 2:  " is"
Chunk 3:  " a"
Chunk 4:  " JavaScript"
Chunk 5:  " library"
...

User sees on screen (accumulates):
"React"
"React is"
"React is a"
"React is a JavaScript"
"React is a JavaScript library"
```

**Update Types:**

```javascript
// 1. Text chunks (agent typing)
{
  sessionUpdate: 'agent_message_chunk',
  content: {
    type: 'text',
    text: 'React is '  // Partial text
  }
}

// 2. Tool calls (agent using tools)
{
  sessionUpdate: 'tool_call',
  title: 'read_file',
  toolCallId: 'call_xyz123'
}

// 3. Tool results
{
  sessionUpdate: 'tool_call_update',
  toolCallId: 'call_xyz123',
  status: 'success'
}

// 4. Planning (agent's thought process)
{
  sessionUpdate: 'plan',
  content: {
    type: 'text',
    text: 'First I will read the file, then analyze it'
  }
}
```

### 3. Tool Permissions

**What are Tools?**
Tools are capabilities that allow the AI agent to interact with the system:
- `read_file` - Read file contents
- `write_file` - Modify or create files
- `run_command` - Execute shell commands
- `list_directory` - List files in a folder
- `search_files` - Search for text in files

**Permission Flow:**

```
┌─────────┐                                              ┌─────────┐
│  Agent  │                                              │  User   │
└────┬────┘                                              └────┬────┘
     │                                                        │
     │ "I need to read package.json"                         │
     │                                                        │
     │──────── Tool Permission Request ────────────────────→ │
     │  {                                                     │
     │    toolCall: {                                         │
     │      title: "read_file: package.json"               │
     │    },                                                  │
     │    options: [                                          │
     │      { kind: "allow_once", optionId: "123" },        │
     │      { kind: "allow_always", optionId: "456" },      │
     │      { kind: "reject_once", optionId: "789" }        │
     │    ]                                                   │
     │  }                                                     │
     │                                                        │
     │                                                        │  User decides:
     │                                                        │  "Yes, allow"
     │                                                        │
     │ ←────── Permission Response ────────────────────────  │
     │  {                                                     │
     │    outcome: {                                          │
     │      outcome: "selected",                             │
     │      optionId: "123"  // allow_once                   │
     │    }                                                   │
     │  }                                                     │
     │                                                        │
     │  Reads file...                                         │
     │                                                        │
     │──────── Tool Result ──────────────────────────────→   │
     │  "File contents: { ... }"                             │
     │                                                        │
     └────────────────────────────────────────────────────────┘
```

**Auto-approval for Safe Operations:**

```javascript
// Safe tools (auto-approved)
const safeTools = ['read_file', 'list_directory', 'search_files'];

// Dangerous tools (require user confirmation)
const dangerousTools = ['write_file', 'run_command', 'delete_file'];
```

---

## Protocol Deep Dive

### ACP Message Format

ACP uses **JSON-RPC 2.0** over **newline-delimited JSON (nd-JSON)**.

**What is nd-JSON?**
```
Regular JSON: { "method": "test" }

nd-JSON: One JSON object per line:
{"jsonrpc":"2.0","method":"initialize","id":1}\n
{"jsonrpc":"2.0","method":"session/new","id":2}\n
{"jsonrpc":"2.0","method":"session/prompt","id":3}\n
```

### Complete Message Flow

#### 1. Initialize Protocol

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": 1,
    "clientCapabilities": {
      "fs": { "readTextFile": true, "writeTextFile": true },
      "terminal": true
    },
    "clientInfo": {
      "name": "interactive-chat",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "protocolVersion": 1,
    "serverCapabilities": {
      "tools": ["read_file", "write_file", "run_command"]
    },
    "serverInfo": {
      "name": "claude-agent-acp",
      "version": "0.23.1"
    }
  },
  "id": 1
}
```

#### 2. Create Session

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "session/new",
  "params": {
    "cwd": "/Users/user/project",
    "mcpServers": []
  },
  "id": 2
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "sessionId": "75ddb14b-975b-45e6-9058-4569844535de"
  },
  "id": 2
}
```

#### 3. Send Prompt

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "session/prompt",
  "params": {
    "sessionId": "75ddb14b-975b-45e6-9058-4569844535de",
    "prompt": [
      {
        "type": "text",
        "text": "What is React?"
      }
    ]
  },
  "id": 3
}
```

**Streaming Responses (Notifications - no id):**
```json
{"jsonrpc":"2.0","method":"session/notification","params":{"update":{"sessionUpdate":"agent_message_chunk","content":{"type":"text","text":"React"}}}}
{"jsonrpc":"2.0","method":"session/notification","params":{"update":{"sessionUpdate":"agent_message_chunk","content":{"type":"text","text":" is"}}}}
{"jsonrpc":"2.0","method":"session/notification","params":{"update":{"sessionUpdate":"agent_message_chunk","content":{"type":"text","text":" a"}}}}
```

**Final Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "stopReason": "end_turn",
    "usage": {
      "inputTokens": 125,
      "outputTokens": 456
    }
  },
  "id": 3
}
```

---

## Code Walkthrough

### File Structure

```
05-claude-code-integration/
├── package.json                 # Dependencies
├── test-connection.js          # Quick connection test
├── claude-code-real.js         # Demo with examples
├── interactive-chat.js         # Interactive chat loop ⭐
├── README.md                   # Usage guide
├── QUICKSTART.md              # Quick start guide
└── KNOWLEDGE-TRANSFER.md      # This file
```

### interactive-chat.js - Complete Breakdown

#### Part 1: Imports and Setup

```javascript
import { spawn } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { ClientSideConnection, ndJsonStream, PROTOCOL_VERSION } from '@agentclientprotocol/sdk';
import * as readline from 'node:readline';
```

**What each import does:**
- `spawn` - Launch the ACP wrapper as a child process
- `Readable/Writable` - Convert Node streams to Web streams for SDK
- `ClientSideConnection` - Main SDK class for connecting to agents
- `ndJsonStream` - Creates bidirectional nd-JSON stream
- `PROTOCOL_VERSION` - Current protocol version (1)
- `readline` - Interactive terminal input/output

#### Part 2: Client Class Structure

```javascript
class InteractiveChatClient {
  constructor() {
    this.client = null;      // SDK ClientSideConnection instance
    this.process = null;     // Child process running ACP wrapper
    this.sessionId = null;   // Current session UUID
    this.isResponding = false;
    this.currentResponse = '';
  }
  
  // Methods:
  // - connect()               Initialize connection
  // - sendMessage(text)       Send a message
  // - handleSessionUpdate()   Process streaming responses
  // - handlePermissionRequest() Handle tool permissions
  // - close()                 Cleanup
}
```

#### Part 3: Connection Flow (Detailed)

```javascript
async connect() {
  // Step 1: Spawn the ACP wrapper process
  this.process = spawn('npx', ['-y', '@agentclientprotocol/claude-agent-acp'], {
    stdio: ['pipe', 'pipe', 'pipe'],  // stdin, stdout, stderr
    env: {
      ...process.env,  // Pass all environment variables
      ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY
    }
  });
```

**What's happening:**
```
Your Code                      System
   │
   │ spawn('npx', ...)
   ├──────────────────────────→ npx starts
   │                            │
   │                            ├→ Downloads @agentclientprotocol/claude-agent-acp (if needed)
   │                            │
   │                            └→ Launches claude-agent-acp process
   │
   │ ← Process started
   │
   └─→ proc.stdin, proc.stdout, proc.stderr available
```

```javascript
  // Step 2: Create ACP streams
  const input = Writable.toWeb(this.process.stdin);
  const output = Readable.toWeb(this.process.stdout);
  const stream = ndJsonStream(input, output);
```

**Stream conversion:**
```
Node.js Stream          Web Stream           nd-JSON Stream
                                            
proc.stdin     →  Writable.toWeb()  →  ┌─────────────┐
                                        │             │
                                        │  ndJSON     │
                                        │  Stream     │
                                        │             │
proc.stdout    ← Readable.toWeb()  ←  └─────────────┘
```

```javascript
  // Step 3: Create SDK client with handlers
  this.client = new ClientSideConnection(
    () => ({
      sessionUpdate: async (notification) => {
        this.handleSessionUpdate(notification);
      },
      requestPermission: async (params) => {
        return this.handlePermissionRequest(params);
      }
    }),
    stream
  );
```

**Handler callbacks:**
```
Wrapper sends notification
        │
        ▼
   ndJSON Stream
        │
        ▼
ClientSideConnection
        │
        ├─→ sessionUpdate() ──→ handleSessionUpdate()
        │                        │
        │                        └─→ Print text chunks
        │
        └─→ requestPermission() ──→ handlePermissionRequest()
                                    │
                                    └─→ Ask user / auto-approve
```

```javascript
  // Step 4: Initialize protocol
  await this.client.initialize({
    protocolVersion: PROTOCOL_VERSION,
    clientCapabilities: {
      fs: { readTextFile: true, writeTextFile: true },
      terminal: true
    },
    clientInfo: {
      name: 'interactive-chat',
      version: '1.0.0'
    }
  });
```

**Protocol handshake:**
```
Client                           Wrapper
  │
  │ initialize({...})
  ├──────────────────────────────→│
  │                                │ Validates protocol version
  │                                │ Checks capabilities
  │                                │
  │ ←─────────────────────────────┤
  │   { serverCapabilities, ... }
  │
  ✓ Connection established
```

```javascript
  // Step 5: Create session
  const session = await this.client.newSession({
    cwd: process.cwd(),
    mcpServers: []
  });
  
  this.sessionId = session.sessionId;
}
```

**Session creation:**
```
Client                                Wrapper
  │
  │ newSession({ cwd, ... })
  ├────────────────────────────────→│
  │                                  │ Creates new session
  │                                  │ Allocates UUID
  │                                  │ Sets working directory
  │                                  │
  │ ←────────────────────────────────┤
  │   { sessionId: "uuid..." }
  │
  ✓ Session ready for messages
```

#### Part 4: Sending Messages

```javascript
async sendMessage(text) {
  this.isResponding = true;
  this.currentResponse = '';

  const response = await this.client.prompt({
    sessionId: this.sessionId,
    prompt: [
      {
        type: 'text',
        text: text  // User's message
      }
    ]
  });

  this.isResponding = false;
  return response;
}
```

**Prompt flow:**
```
User types: "Hello"
      │
      ▼
sendMessage("Hello")
      │
      ▼
client.prompt({
  sessionId: "uuid",
  prompt: [{ type: "text", text: "Hello" }]
})
      │
      ▼
Sends to wrapper ────────────────┐
                                  │
      Wrapper processes          │
         ↓                        │
      Calls Anthropic API        │
         ↓                        │
      Receives response          │
         ↓                        │
      ┌──────────────────────────┘
      │
      ▼
Streams back chunks via sessionUpdate()
      │
      ▼
handleSessionUpdate() prints each chunk
      │
      ▼
Final response returned
```

#### Part 5: Handling Streaming Updates

```javascript
handleSessionUpdate(notification) {
  const update = notification.update;
  
  if (!('sessionUpdate' in update)) {
    return;
  }

  switch (update.sessionUpdate) {
    case 'agent_message_chunk':
      // Stream Claude's response as it types
      if (update.content?.type === 'text') {
        process.stdout.write(update.content.text);
        this.currentResponse += update.content.text;
      }
      break;

    case 'tool_call':
      // Claude is using a tool
      const toolName = update.title || 'unknown';
      console.log(`\n\n🔧 Using tool: ${toolName}`);
      break;

    case 'tool_call_update':
      // Tool execution progress
      if (update.status === 'success') {
        console.log(`✅ Tool completed`);
      } else if (update.status === 'error') {
        console.log(`❌ Tool failed`);
      }
      break;
  }
}
```

**Visual update flow:**
```
Wrapper                 handleSessionUpdate()        Terminal
  │
  │ Chunk 1: "Hello"
  ├──────────────────→ process.stdout.write()  →  "Hello"
  │
  │ Chunk 2: " world"
  ├──────────────────→ process.stdout.write()  →  "Hello world"
  │
  │ Tool call: read_file
  ├──────────────────→ console.log()           →  "🔧 Using tool: read_file"
  │
  │ Tool result: success
  ├──────────────────→ console.log()           →  "✅ Tool completed"
  │
  │ Chunk 3: "!"
  ├──────────────────→ process.stdout.write()  →  "Hello world!"
  │
  ▼
```

#### Part 6: Interactive Loop

```javascript
// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  prompt: '\n\x1b[36mYou:\x1b[0m '  // Cyan "You:" prompt
});

rl.prompt();  // Show initial prompt

rl.on('line', async (input) => {
  const message = input.trim();
  
  // Handle commands (/exit, /help, /clear)
  if (message.startsWith('/')) {
    // ... command handling
    return;
  }
  
  // Send message to Claude
  await client.sendMessage(message);
  
  // Show prompt again (continues loop)
  rl.prompt();
});
```

**Loop visualization:**
```
Start
  │
  ▼
┌──────────────┐
│ Show prompt  │  "You: "
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Wait for     │  User types...
│ user input   │
└──────┬───────┘
       │
       ▼
  User presses Enter
       │
       ▼
┌──────────────┐
│ Process      │  Check if command or message
│ input        │
└──────┬───────┘
       │
       ├─→ Command? ─→ Execute command ─┐
       │                                 │
       └─→ Message? ─→ Send to Claude ──┤
                                         │
                                         ▼
                                    Show prompt
                                         │
                                         └──→ (Loop repeats)
```

---

## Integration Patterns

### Pattern 1: Simple One-Shot Query

```javascript
import { InteractiveChatClient } from './interactive-chat.js';

async function askQuestion(question) {
  const client = new InteractiveChatClient();
  
  await client.connect();
  const response = await client.sendMessage(question);
  client.close();
  
  return response;
}

// Usage
const answer = await askQuestion('What is the capital of France?');
console.log(answer);
```

### Pattern 2: Multi-Turn Conversation

```javascript
async function conversation() {
  const client = new InteractiveChatClient();
  await client.connect();
  
  // Turn 1
  await client.sendMessage('What is React?');
  
  // Turn 2 (context maintained)
  await client.sendMessage('Show me an example');
  
  // Turn 3 (still has context from Turn 1 & 2)
  await client.sendMessage('How do I add state?');
  
  client.close();
}
```

### Pattern 3: Tool-Assisted Tasks

```javascript
async function analyzeProject() {
  const client = new InteractiveChatClient();
  await client.connect();
  
  // Claude will use tools automatically
  await client.sendMessage(
    'Read package.json and summarize the dependencies'
  );
  
  // Tool flow:
  // 1. Claude requests permission to read_file
  // 2. handlePermissionRequest() auto-approves (safe tool)
  // 3. File is read
  // 4. Claude analyzes content
  // 5. Response streamed back
  
  client.close();
}
```

### Pattern 4: Batch Processing

```javascript
async function processFiles(files) {
  const client = new InteractiveChatClient();
  await client.connect();
  
  for (const file of files) {
    await client.sendMessage(`Analyze ${file}`);
  }
  
  client.close();
}
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Invalid params" Error

**Symptom:**
```
Error handling request {
  jsonrpc: '2.0',
  method: 'session/prompt',
  params: {
    sessionId: 'uuid',
    text: 'Hello'  // ❌ Wrong format!
  }
}
```

**Problem:** Using `text` directly instead of `prompt` array.

**Solution:**
```javascript
// ❌ Wrong
client.prompt({
  sessionId: sessionId,
  text: 'Hello'
});

// ✅ Correct
client.prompt({
  sessionId: sessionId,
  prompt: [
    {
      type: 'text',
      text: 'Hello'
    }
  ]
});
```

#### Issue 2: Connection Hangs

**Symptom:** Script gets stuck at "Connecting to Claude..."

**Possible Causes:**
1. Using standard `claude` CLI instead of ACP wrapper
2. Network issues
3. Wrapper downloading (slow internet)

**Solution:**
```javascript
// ❌ Wrong - standard CLI doesn't speak ACP
spawn('claude', [], ...)

// ✅ Correct - ACP-compatible wrapper
spawn('npx', ['-y', '@agentclientprotocol/claude-agent-acp'], ...)
```

#### Issue 3: API Key Issues

**Symptom:** Authentication errors

**Check:**
```bash
# Is the key set?
echo $ANTHROPIC_API_KEY

# Is it valid format?
# Should start with: sk-ant-

# Set it properly:
export ANTHROPIC_API_KEY="sk-ant-..."

# Make permanent:
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
source ~/.zshrc
```

### Debug Mode

Add debug logging to see protocol messages:

```javascript
// In connect() method, before creating ClientSideConnection:

// Log all messages going to wrapper
this.process.stdin.on('data', (data) => {
  console.log('→ TO WRAPPER:', data.toString());
});

// Log all messages from wrapper
this.process.stdout.on('data', (data) => {
  console.log('← FROM WRAPPER:', data.toString());
});
```

---

## Best Practices

### 1. Error Handling

Always wrap SDK calls in try-catch:

```javascript
try {
  await client.connect();
  await client.sendMessage(text);
} catch (error) {
  console.error('Error:', error.message);
  // Cleanup
  client.close();
}
```

### 2. Resource Cleanup

Always close connections when done:

```javascript
// Method 1: Explicit close
client.close();

// Method 2: Handle process exit
process.on('exit', () => {
  client.close();
});

// Method 3: Handle Ctrl+C
process.on('SIGINT', () => {
  client.close();
  process.exit(0);
});
```

### 3. Permission Management

Be thoughtful about auto-approvals:

```javascript
// Safe to auto-approve
const safeTools = [
  'read_file',       // Reading is safe
  'list_directory',  // Listing is safe
  'search_files'     // Searching is safe
];

// Always ask user
const dangerousTools = [
  'write_file',      // Modifies files
  'delete_file',     // Destructive
  'run_command'      // Could do anything
];
```

### 4. Session Management

Reuse sessions for related conversations:

```javascript
// ✅ Good - One session, multiple messages
const client = new InteractiveChatClient();
await client.connect();

await client.sendMessage('Question 1');
await client.sendMessage('Question 2');  // Has context from Q1
await client.sendMessage('Question 3');  // Has context from Q1 & Q2

client.close();

// ❌ Bad - New session each time (loses context)
await askOneShot('Question 1');
await askOneShot('Question 2');  // No context!
await askOneShot('Question 3');  // No context!
```

### 5. Streaming Display

Show progress indicators during long operations:

```javascript
handleSessionUpdate(notification) {
  const update = notification.update;
  
  switch (update.sessionUpdate) {
    case 'agent_message_chunk':
      // Show text as it arrives
      process.stdout.write(update.content.text);
      break;
      
    case 'tool_call':
      // Show user what's happening
      console.log(`\n🔧 ${update.title}...`);
      break;
      
    case 'plan':
      // Show Claude's reasoning
      console.log(`\n💭 Plan: ${update.content.text}`);
      break;
  }
}
```

---

## Summary

### Key Takeaways

1. **ACP is a universal protocol** for AI agents - write once, works everywhere
2. **The wrapper is a separate process** - spawned via child_process, communicates via stdin/stdout
3. **Protocol is JSON-RPC over nd-JSON** - one JSON object per line
4. **Sessions maintain context** - use one session for related messages
5. **Streaming is real-time** - responses appear chunk by chunk as generated
6. **Tools require permissions** - balance safety with convenience
7. **SDK handles complexity** - ClientSideConnection manages protocol details

### Architecture in One Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Your JavaScript Code                          │
│  • Import @agentclientprotocol/sdk                              │
│  • Create ClientSideConnection                                   │
│  • Handle sessionUpdate callbacks                                │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ spawn + stdio pipes
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│             @agentclientprotocol/claude-agent-acp                │
│  • Receives JSON-RPC messages via stdin                         │
│  • Translates to Anthropic API calls                            │
│  • Streams responses back via stdout                             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ HTTPS
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                      Anthropic API                               │
│  • Claude 3.5 Sonnet                                            │
│  • Claude 3 Opus                                                 │
│  • etc.                                                          │
└─────────────────────────────────────────────────────────────────┘
```

### Next Steps

1. **Run the examples** - Start with `npm run chat`
2. **Read the code** - Follow along in `interactive-chat.js`
3. **Experiment** - Modify examples to try new ideas
4. **Build something** - Use the patterns to create your own integration
5. **Explore OpenClaw** - See production implementation in `src/acp/`

---

## Additional Resources

- [ACP Protocol Specification](https://agentclientprotocol.com/)
- [SDK Documentation](https://www.npmjs.com/package/@agentclientprotocol/sdk)
- [OpenClaw Source Code](https://github.com/openclaw/openclaw)
- [Main POC README](../README.md)
- [Quick Start Guide](./QUICKSTART.md)

---

**Questions?** Open an issue on GitHub or check the [OpenClaw Discord](https://discord.gg/openclaw).

**Happy coding!** 🎉
