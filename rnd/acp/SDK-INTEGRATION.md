# How @agentclientprotocol/sdk is Integrated in OpenClaw

## Overview

The `@agentclientprotocol/sdk` package provides the foundation for OpenClaw's ACP (Agent Client Protocol) implementation. It offers two main connection types:

1. **`AgentSideConnection`** - Used by OpenClaw to act as an ACP server (receives requests from external agents)
2. **`ClientSideConnection`** - Used by OpenClaw to act as an ACP client (sends requests to external agents)

## Package Information

**Location in package.json:**
```json
"dependencies": {
  "@agentclientprotocol/sdk": "0.16.1"
}
```

**Usage Pattern:** OpenClaw uses this SDK to bridge between its internal gateway (WebSocket-based) and external ACP-compatible agents like Codex, Claude Code, Gemini CLI, etc.

## Key Integration Points

### 1. Server-Side Integration (AgentSideConnection)

**File:** `src/acp/server.ts`

OpenClaw acts as an **ACP server** that external agents can connect to.

```typescript
import { AgentSideConnection, ndJsonStream } from "@agentclientprotocol/sdk";

export async function serveAcpGateway(opts: AcpServerOptions = {}): Promise<void> {
  // 1. Connect to OpenClaw Gateway (WebSocket)
  const gateway = new GatewayClient({
    url: connection.url,
    token: creds.token,
    password: creds.password,
    onEvent: (evt) => {
      void agent?.handleGatewayEvent(evt);
    }
  });

  // 2. Set up ACP streaming via stdin/stdout
  const input = Writable.toWeb(process.stdout);
  const output = Readable.toWeb(process.stdin);
  const stream = ndJsonStream(input, output);

  // 3. Create AgentSideConnection
  new AgentSideConnection((conn: AgentSideConnection) => {
    agent = new AcpGatewayAgent(conn, gateway, opts);
    agent.start();
    return agent;
  }, stream);
}
```

**What this does:**
- External agents (like Codex) connect via stdin/stdout
- The SDK handles the ACP protocol (JSON-RPC over newline-delimited JSON)
- OpenClaw's `AcpGatewayAgent` translates between ACP and its internal gateway protocol

### 2. Client-Side Integration (ClientSideConnection)

**File:** `src/acp/client.ts`

OpenClaw acts as an **ACP client** that spawns and controls external agents.

```typescript
import {
  ClientSideConnection,
  PROTOCOL_VERSION,
  ndJsonStream,
  type RequestPermissionRequest,
  type RequestPermissionResponse,
  type SessionNotification,
} from "@agentclientprotocol/sdk";

export async function spawnAcpClient(params: AcpClientParams): Promise<AcpClientHandle> {
  // 1. Spawn the external agent process
  const proc = spawn(command, args, {
    stdio: ["pipe", "pipe", "inherit"],
    env: cleanEnv,
    cwd: params.cwd
  });

  // 2. Create streams for communication
  const input = Writable.toWeb(proc.stdin);
  const output = Readable.toWeb(proc.stdout);
  const stream = ndJsonStream(input, output);

  // 3. Create ClientSideConnection
  const connection = new ClientSideConnection(() => {
    return {
      agent: {
        name: "openclaw-acp-client",
        version: VERSION,
      },
      
      // Handle permission requests from the agent
      async requestPermission(params: RequestPermissionRequest): Promise<RequestPermissionResponse> {
        // Validate tool calls before approving
        const toolName = resolveToolNameForPermission(params);
        const isSafe = SAFE_AUTO_APPROVE_TOOL_IDS.has(toolName || "");
        
        if (isSafe) {
          return { allowed: true };
        }
        
        // Prompt user for dangerous tools
        const approved = await promptUser(toolName);
        return { allowed: approved };
      },

      // Handle session notifications
      async sessionUpdate(notification: SessionNotification): Promise<void> {
        // Process session state changes
        console.log("Session updated:", notification);
      }
    };
  }, stream);

  return { connection, process: proc };
}
```

**What this does:**
- Spawns external agents as child processes
- Uses the SDK to communicate via pipes
- Handles permission requests (tool calls need approval)
- Receives session updates from the agent

### 3. Type Definitions Used

**File:** `src/acp/translator.ts`

The SDK provides comprehensive TypeScript types:

```typescript
import type {
  Agent,
  AgentSideConnection,
  AuthenticateRequest,
  AuthenticateResponse,
  CancelNotification,
  InitializeRequest,
  InitializeResponse,
  ListSessionsRequest,
  ListSessionsResponse,
  LoadSessionRequest,
  LoadSessionResponse,
  NewSessionRequest,
  NewSessionResponse,
  PromptRequest,
  PromptResponse,
  SessionConfigOption,
  SessionModeState,
  SetSessionConfigOptionRequest,
  SetSessionConfigOptionResponse,
  SetSessionModeRequest,
  SetSessionModeResponse,
  StopReason,
  ToolCallLocation,
  ToolKind,
} from "@agentclientprotocol/sdk";
import { PROTOCOL_VERSION } from "@agentclientprotocol/sdk";
```

**Common Types:**

- **`PromptRequest`**: When agent sends a user message
- **`PromptResponse`**: Response with text/tool results
- **`ToolCallLocation`**: Where in the codebase a tool is acting
- **`SessionNotification`**: Session state updates
- **`RequestPermissionRequest`**: Agent asking to use a tool

## How It All Works Together

### Flow 1: External Agent → OpenClaw (Server Mode)

```
┌─────────────────┐
│  Codex CLI      │
│  (external)     │
└────────┬────────┘
         │
         │ stdin/stdout (ACP protocol)
         │
         ▼
┌─────────────────────────────┐
│  @agentclientprotocol/sdk   │
│  AgentSideConnection        │
│  - Parses ACP messages      │
│  - Handles protocol details │
└────────┬────────────────────┘
         │
         │ Callbacks to AcpGatewayAgent
         │
         ▼
┌─────────────────────────────┐
│  AcpGatewayAgent            │
│  (src/acp/translator.ts)    │
│  - Translates ACP → Gateway │
└────────┬────────────────────┘
         │
         │ WebSocket
         │
         ▼
┌─────────────────────────────┐
│  OpenClaw Gateway           │
│  - Routes messages          │
│  - Manages sessions         │
└─────────────────────────────┘
```

### Flow 2: OpenClaw → External Agent (Client Mode)

```
┌─────────────────────────────┐
│  OpenClaw Gateway           │
│  User sends: "Fix the bug"  │
└────────┬────────────────────┘
         │
         │ WebSocket
         │
         ▼
┌─────────────────────────────┐
│  ACP Runtime Backend        │
│  Spawns external agent      │
└────────┬────────────────────┘
         │
         │ stdin/stdout
         │
         ▼
┌─────────────────────────────┐
│  @agentclientprotocol/sdk   │
│  ClientSideConnection       │
│  - Sends ACP messages       │
│  - Receives responses       │
└────────┬────────────────────┘
         │
         │ stdin/stdout (ACP protocol)
         │
         ▼
┌─────────────────┐
│  Claude Code    │
│  (external)     │
└─────────────────┘
```

## Protocol Details

The SDK handles the **ACP wire format**:

```json
{"jsonrpc":"2.0","method":"session/new","params":{"mode":"persistent"},"id":1}
{"jsonrpc":"2.0","method":"session/prompt","params":{"text":"Hello"},"id":2}
{"jsonrpc":"2.0","result":{"text":"Hi there!"},"id":2}
```

Key features the SDK provides:

1. **JSON-RPC 2.0 over newline-delimited JSON**
2. **Request/Response mapping** (id correlation)
3. **Notification handling** (no id, one-way)
4. **Error handling** (standard JSON-RPC error format)
5. **Stream management** (handles backpressure)

## Protocol Version

OpenClaw uses **ACP protocol version** from the SDK:

```typescript
import { PROTOCOL_VERSION } from "@agentclientprotocol/sdk";

// Current version: "0.1.0" (as of SDK 0.16.1)
```

## Security Integration

The SDK's permission system is integrated into OpenClaw's security model:

**File:** `src/acp/client.ts`

```typescript
async requestPermission(params: RequestPermissionRequest): Promise<RequestPermissionResponse> {
  // Extract tool information
  const toolName = resolveToolNameForPermission(params);
  const toolKind = resolveToolKindForPermission(toolName);
  
  // Auto-approve safe tools
  if (SAFE_AUTO_APPROVE_TOOL_IDS.has(toolName || "")) {
    return { allowed: true };
  }
  
  // Block dangerous tools
  if (DANGEROUS_ACP_TOOLS.has(toolName || "")) {
    return { 
      allowed: false, 
      reason: "Tool is marked as dangerous" 
    };
  }
  
  // Validate file paths stay within workspace
  if (toolName === "read") {
    const pathScoped = isReadToolCallScopedToCwd(params, toolName, toolTitle, cwd);
    if (!pathScoped) {
      return { 
        allowed: false, 
        reason: "Path outside workspace" 
      };
    }
  }
  
  // Prompt user for approval
  const approved = await prompt(toolName, toolTitle);
  return { allowed: approved };
}
```

## Helper Functions from SDK

### `ndJsonStream()`

Creates a bidirectional stream for ACP communication:

```typescript
const stream = ndJsonStream(
  input,   // WritableStream
  output   // ReadableStream
);
```

### Protocol Constants

```typescript
PROTOCOL_VERSION  // "0.1.0"
```

## Real-World Example

Here's how a complete interaction works:

**1. User sends message in Discord**
```
User: "Fix the auth bug"
```

**2. OpenClaw routes to ACP session**
```typescript
// Binding resolves to ACP session
const binding = bindingManager.resolveBinding("discord", "bot-123", "channel-dev");
// binding.backend = "codex"
```

**3. OpenClaw spawns Codex (Client Mode)**
```typescript
// src/acp/client.ts
const client = await spawnAcpClient({
  command: "codex",
  args: [],
  cwd: "/path/to/workspace"
});

// SDK sends:
// {"jsonrpc":"2.0","method":"session/new","params":{"mode":"persistent"},"id":1}
```

**4. Codex responds via ACP**
```json
{"jsonrpc":"2.0","method":"session/notification","params":{"type":"text_delta","text":"Reading auth.ts..."}}
{"jsonrpc":"2.0","method":"session/request_permission","params":{"toolCall":{"title":"read_file: auth.ts"}},"id":2}
```

**5. OpenClaw approves tool (via SDK)**
```json
{"jsonrpc":"2.0","result":{"allowed":true},"id":2}
```

**6. Codex continues**
```json
{"jsonrpc":"2.0","method":"session/notification","params":{"type":"tool_result","content":"// auth.ts..."}}
{"jsonrpc":"2.0","result":{"text":"Found the bug! ..."},"id":1}
```

**7. OpenClaw sends response back to Discord**

## SDK Files Used in OpenClaw

| SDK Export | Used In | Purpose |
|------------|---------|---------|
| `AgentSideConnection` | `server.ts`, `translator.ts` | Act as ACP server |
| `ClientSideConnection` | `client.ts` | Act as ACP client |
| `ndJsonStream` | `server.ts`, `client.ts` | Stream protocol handler |
| `PROTOCOL_VERSION` | `translator.ts` | Protocol compatibility |
| `RequestPermissionRequest` | `client.ts` | Tool permission types |
| `SessionNotification` | `translator.ts` | Session updates |
| `PromptRequest/Response` | `translator.ts`, tests | Message types |
| All other types | Throughout | Type safety |

## Testing with the SDK

**File:** `src/acp/server.startup.test.ts`

```typescript
vi.mock("@agentclientprotocol/sdk", () => ({
  AgentSideConnection: vi.fn(),
  ndJsonStream: vi.fn(),
  PROTOCOL_VERSION: "0.1.0"
}));
```

## Summary

The `@agentclientprotocol/sdk` package provides:

1. ✅ **Protocol Implementation** - JSON-RPC 2.0 over nd-JSON
2. ✅ **Connection Management** - Both server and client sides
3. ✅ **Type Definitions** - Full TypeScript support
4. ✅ **Stream Handling** - Bidirectional communication
5. ✅ **Permission System** - Tool approval workflow
6. ✅ **Session Management** - Notification system

OpenClaw uses it to:

- Bridge external agents (Codex, Claude) to its internal gateway
- Handle tool permissions securely
- Maintain protocol compatibility
- Stream agent responses in real-time

**Key Insight:** The SDK handles the low-level protocol details (JSON-RPC, streaming, message correlation), allowing OpenClaw to focus on higher-level concerns (routing, security, session management).

---

## References

- ACP Spec: https://agentclientprotocol.com/
- OpenClaw ACP Server: [src/acp/server.ts](../src/acp/server.ts)
- OpenClaw ACP Client: [src/acp/client.ts](../src/acp/client.ts)
- ACP Translator: [src/acp/translator.ts](../src/acp/translator.ts)
- OpenClaw Docs: [docs/tools/acp-agents.md](../docs/tools/acp-agents.md)
