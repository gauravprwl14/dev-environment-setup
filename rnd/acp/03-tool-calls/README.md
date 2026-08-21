# Example 3: Agent Tool Calls

## What This Example Shows

How agents execute actions (reading files, running commands, searching, etc.) through the tool system.

**The Problem**: Agents need to *do things*, not just chat:
- Read code files
- Write/edit files  
- Run commands
- Search the web
- Access databases

**The Solution**: Tool calls - structured actions the agent can request.

## The Tool Call Flow

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│              │         │              │         │              │
│    Agent     │-------->│  Tool System │-------->│  Execution   │
│              │ request │              │ execute │              │
└──────────────┘         └──────────────┘         └──────────────┘
       │                         │                         │
       │                         │                         │
       │  1. "Read auth.ts"      │                         │
       │  Tool: read_file        │                         │
       │  params: {              │                         │
       │    path: "auth.ts",     │                         │
       │    startLine: 1,        │                         │
       │    endLine: 50          │                         │
       │  }                      │                         │
       │─────────────────────────>                         │
       │                         │                         │
       │                         │  2. Execute read        │
       │                         │─────────────────────────>
       │                         │                         │
       │                         │  3. File contents       │
       │                         │<─────────────────────────
       │                         │                         │
       │  4. Tool result         │                         │
       │<─────────────────────────                         │
       │  content: "import..."   │                         │
       │  success: true          │                         │
       │                         │                         │
```

## Tool Types

### 1. Read Tools
- `read_file` - Read file contents
- `search` - Search codebase
- `list_directory` - List files

### 2. Write Tools
- `write_file` - Create/overwrite files
- `edit_file` - Modify existing files

### 3. Execution Tools
- `run_command` - Execute shell commands
- `run_script` - Run scripts

### 4. Search Tools
- `web_search` - Search the internet
- `memory_search` - Search agent memory

## Code Example

### Tool System Implementation

```javascript
class ToolSystem {
  constructor() {
    // Register available tools
    this.tools = new Map();
    this.registerBuiltinTools();
  }

  registerBuiltinTools() {
    // Read file tool
    this.tools.set('read_file', {
      name: 'read_file',
      description: 'Read contents of a file',
      parameters: {
        path: { type: 'string', required: true },
        startLine: { type: 'number', required: false },
        endLine: { type: 'number', required: false }
      },
      handler: this.handleReadFile.bind(this)
    });

    // Search tool
    this.tools.set('search', {
      name: 'search',
      description: 'Search for patterns in codebase',
      parameters: {
        query: { type: 'string', required: true },
        includePattern: { type: 'string', required: false }
      },
      handler: this.handleSearch.bind(this)
    });

    // Write file tool
    this.tools.set('write_file', {
      name: 'write_file',
      description: 'Write content to a file',
      parameters: {
        path: { type: 'string', required: true },
        content: { type: 'string', required: true }
      },
      handler: this.handleWriteFile.bind(this)
    });
  }

  /**
   * Execute a tool call
   */
  async executeTool(toolName, params) {
    const tool = this.tools.get(toolName);
    
    if (!tool) {
      throw new Error(`Unknown tool: ${toolName}`);
    }

    console.log(`🔧 Executing tool: ${toolName}`);
    console.log(`   Params:`, JSON.stringify(params, null, 2));

    try {
      const result = await tool.handler(params);
      console.log(`✅ Tool succeeded`);
      return {
        success: true,
        content: result,
        toolName
      };
    } catch (error) {
      console.log(`❌ Tool failed: ${error.message}`);
      return {
        success: false,
        error: error.message,
        toolName
      };
    }
  }

  // Tool handlers (simplified implementations)
  
  async handleReadFile(params) {
    const { path, startLine = 1, endLine } = params;
    
    // Simulate reading a file
    await sleep(100);
    
    const mockContent = `
// ${path}
export function authenticate(user, password) {
  if (!user || !password) {
    throw new Error('Missing credentials');
  }
  return validateCredentials(user, password);
}
    `.trim();

    return mockContent;
  }

  async handleSearch(params) {
    const { query, includePattern } = params;
    
    // Simulate searching
    await sleep(150);
    
    return `Found 3 matches for "${query}":
1. auth.ts:15 - function authenticate(user, password)
2. auth.test.ts:8 - describe('authenticate', () => {
3. auth.service.ts:22 - await authenticate(req.user, req.pass)`;
  }

  async handleWriteFile(params) {
    const { path, content } = params;
    
    // Simulate writing
    await sleep(100);
    
    return `Wrote ${content.length} bytes to ${path}`;
  }
}
```

### Agent with Tool Support

```javascript
class AgentWithTools {
  constructor(toolSystem) {
    this.toolSystem = toolSystem;
    this.sessions = new Map();
  }

  async *runTurn(input) {
    const { handle, text } = input;
    const session = this.sessions.get(handle.sessionKey) || {
      messages: [],
      mode: 'persistent'
    };

    // Add user message
    session.messages.push({
      role: 'user',
      content: text
    });

    // Simulate agent deciding to use tools
    yield {
      type: 'text_delta',
      text: 'Let me check that file for you...\n'
    };

    // Agent decides to call read_file tool
    const toolCall = {
      toolName: 'read_file',
      params: {
        path: 'auth.ts',
        startLine: 1,
        endLine: 20
      }
    };

    yield {
      type: 'tool_call',
      text: `Calling tool: ${toolCall.toolName}`,
      toolCallId: 'call_1',
      status: 'running',
      title: `read_file: auth.ts`
    };

    // Execute the tool
    const toolResult = await this.toolSystem.executeTool(
      toolCall.toolName,
      toolCall.params
    );

    yield {
      type: 'tool_call',
      text: `Tool completed`,
      toolCallId: 'call_1',
      status: toolResult.success ? 'success' : 'error',
      title: `read_file: auth.ts`
    };

    // Agent processes the result
    yield {
      type: 'text_delta',
      text: `\nI found the authenticate function. Here's what it does:\n`
    };
    
    yield {
      type: 'text_delta',
      text: `It validates user credentials and throws an error if they're missing.\n`
    };

    // Add assistant response to history
    session.messages.push({
      role: 'assistant',
      content: 'Analyzed auth.ts and explained the authenticate function',
      toolCalls: [toolCall],
      toolResults: [toolResult]
    });

    this.sessions.set(handle.sessionKey, session);

    yield { type: 'done', stopReason: 'end_turn' };
  }
}
```

## Running the Example

```bash
cd 03-tool-calls
npm install
npm start
```

**Expected output:**

```
🔧 Agent Tool Calls Demo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 STEP 1: Agent uses read_file tool
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 User: Can you check the authenticate function in auth.ts?

Agent: Let me check that file for you...

🔧 Executing tool: read_file
   Params: {
     "path": "auth.ts",
     "startLine": 1,
     "endLine": 20
   }
✅ Tool succeeded

📄 Tool result:
// auth.ts
export function authenticate(user, password) {
  if (!user || !password) {
    throw new Error('Missing credentials');
  }
  return validateCredentials(user, password);
}

Agent: I found the authenticate function. Here's what it does:
It validates user credentials and throws an error if they're missing.

📍 STEP 2: Agent uses search tool
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 User: Find all uses of authenticate

Agent: Let me search for that...

🔧 Executing tool: search
   Params: {
     "query": "authenticate",
     "includePattern": "**/*.ts"
   }
✅ Tool succeeded

📄 Tool result:
Found 3 matches for "authenticate":
1. auth.ts:15 - function authenticate(user, password)
2. auth.test.ts:8 - describe('authenticate', () => {
3. auth.service.ts:22 - await authenticate(req.user, req.pass)

Agent: Found 3 usages of authenticate across the codebase.

📍 STEP 3: Agent uses multiple tools in sequence
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 User: Add error logging to the authenticate function

Agent: I'll read the file, modify it, and write it back...

🔧 Executing tool: read_file (reading current content)
✅ Tool succeeded

🔧 Executing tool: write_file (writing updated content)
✅ Tool succeeded

Agent: Done! I've added error logging to the authenticate function.

🎉 Demo Complete!
```

## Tool Call Lifecycle

### 1. Request Phase
```javascript
{
  type: 'tool_call',
  toolCallId: 'call_1',
  toolName: 'read_file',
  status: 'running',
  params: {
    path: 'auth.ts'
  }
}
```

### 2. Execution Phase
- Tool system validates params
- Tool handler executes
- Result or error is captured

### 3. Result Phase
```javascript
{
  type: 'tool_result',
  toolCallId: 'call_1',
  success: true,
  content: '// file contents...',
  toolName: 'read_file'
}
```

### 4. Integration Phase
- Agent receives tool result
- Uses it to formulate response
- May chain more tool calls

## Security & Permissions

In production, tools have security checks:

```javascript
class ToolSystem {
  async executeTool(toolName, params) {
    // 1. Check if tool is allowed
    if (!this.isToolAllowed(toolName)) {
      throw new Error(`Tool ${toolName} is not permitted`);
    }

    // 2. Validate params
    this.validateParams(toolName, params);

    // 3. Check permissions (file access, etc.)
    if (toolName === 'write_file') {
      if (!this.canWritePath(params.path)) {
        throw new Error(`Cannot write to ${params.path}`);
      }
    }

    // 4. Execute with sandbox if needed
    const result = await this.executeInSandbox(toolName, params);

    return result;
  }
}
```

## Real-World Tool Examples

### Example 1: Code Analysis Workflow
```
User: "Analyze the security of our auth system"

Agent actions:
1. search(query="password", includePattern="**/*.ts")
2. read_file(path="auth.ts")
3. read_file(path="auth.service.ts")
4. Analyzes code
5. Responds with findings
```

### Example 2: Bug Fix Workflow
```
User: "Fix the null pointer error in auth"

Agent actions:
1. read_file(path="auth.ts")
2. Identifies the issue
3. write_file(path="auth.ts", content=<fixed code>)
4. search(query="authenticate", includePattern="**/*.test.ts")
5. read_file(path="auth.test.ts")
6. Responds with explanation
```

### Example 3: Documentation Workflow
```
User: "Document the authenticate function"

Agent actions:
1. read_file(path="auth.ts")
2. Generates documentation
3. write_file(path="docs/auth.md", content=<docs>)
4. Confirms completion
```

## Key Takeaways

1. **Tools extend agent capabilities**: Beyond chat, agents can act
2. **Tool calls are structured**: Name + params → result
3. **Tools can chain**: One result feeds into next tool
4. **Security matters**: Validate, sandbox, permission-check
5. **Events track progress**: tool_call events show what's happening

## Next Steps

- **Example 4**: See the complete end-to-end integration
- **Real code**: Explore `src/acp/client.ts` for tool handling

---

🔗 [← Back](../02-channel-binding/) | [Main README](../README.md) | [Next: Complete Integration →](../04-complete-integration/)
