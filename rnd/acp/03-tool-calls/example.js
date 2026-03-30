/**
 * Example 3: Agent Tool Calls
 * 
 * This demonstrates how agents execute actions through tools:
 * 1. Tool registration and discovery
 * 2. Tool call lifecycle (request → execute → result)
 * 3. Chaining multiple tools
 * 4. Error handling
 */

// Helper function
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================================================
// Tool System - Manages available tools and execution
// ============================================================================

class ToolSystem {
  constructor() {
    this.tools = new Map();
    this.registerBuiltinTools();
  }

  /**
   * Register all built-in tools
   */
  registerBuiltinTools() {
    // Read file tool
    this.tools.set('read_file', {
      name: 'read_file',
      description: 'Read contents of a file',
      parameters: {
        path: { type: 'string', required: true, description: 'File path' },
        startLine: { type: 'number', required: false, description: 'Start line (1-based)' },
        endLine: { type: 'number', required: false, description: 'End line (inclusive)' }
      },
      handler: this.handleReadFile.bind(this),
      dangerous: false
    });

    // Search tool
    this.tools.set('search', {
      name: 'search',
      description: 'Search for patterns in codebase',
      parameters: {
        query: { type: 'string', required: true, description: 'Search query' },
        includePattern: { type: 'string', required: false, description: 'File pattern to include' }
      },
      handler: this.handleSearch.bind(this),
      dangerous: false
    });

    // Write file tool
    this.tools.set('write_file', {
      name: 'write_file',
      description: 'Write content to a file',
      parameters: {
        path: { type: 'string', required: true, description: 'File path' },
        content: { type: 'string', required: true, description: 'File content' }
      },
      handler: this.handleWriteFile.bind(this),
      dangerous: true  // Writing is potentially dangerous
    });

    console.log(`📚 Registered ${this.tools.size} tools`);
  }

  /**
   * Execute a tool call
   */
  async executeTool(toolName, params, options = {}) {
    const tool = this.tools.get(toolName);

    if (!tool) {
      throw new Error(`Unknown tool: ${toolName}`);
    }

    console.log(`\n🔧 Executing tool: ${toolName}`);
    console.log(`   Params: ${JSON.stringify(params, null, 2)}`);
    
    if (tool.dangerous && !options.allowDangerous) {
      console.log(`   ⚠️  Warning: This is a dangerous tool!`);
    }

    try {
      const startTime = Date.now();
      const result = await tool.handler(params);
      const duration = Date.now() - startTime;
      
      console.log(`✅ Tool succeeded in ${duration}ms`);
      
      return {
        success: true,
        content: result,
        toolName,
        duration
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

  /**
   * Get list of available tools
   */
  listTools() {
    return Array.from(this.tools.values()).map(tool => ({
      name: tool.name,
      description: tool.description,
      parameters: tool.parameters,
      dangerous: tool.dangerous
    }));
  }

  // ===== Tool Handlers =====

  async handleReadFile(params) {
    const { path, startLine = 1, endLine } = params;
    
    console.log(`   Reading ${path}...`);
    await sleep(100);

    // Simulate different file contents based on path
    const mockFiles = {
      'auth.ts': `// auth.ts
export function authenticate(user: string, password: string): boolean {
  if (!user || !password) {
    throw new Error('Missing credentials');
  }
  
  const isValid = validateCredentials(user, password);
  
  if (!isValid) {
    console.error('Authentication failed for user:', user);
  }
  
  return isValid;
}

function validateCredentials(user: string, password: string): boolean {
  // Actual validation logic here
  return true;
}`,
      'auth.test.ts': `// auth.test.ts
import { authenticate } from './auth';

describe('authenticate', () => {
  it('should reject missing credentials', () => {
    expect(() => authenticate('', 'pass')).toThrow('Missing credentials');
  });

  it('should authenticate valid users', () => {
    const result = authenticate('user', 'password');
    expect(result).toBe(true);
  });
});`,
      'auth.service.ts': `// auth.service.ts
import { authenticate } from './auth';

export class AuthService {
  async login(req: LoginRequest): Promise<LoginResponse> {
    const isAuthenticated = await authenticate(req.user, req.password);
    
    if (!isAuthenticated) {
      throw new Error('Invalid credentials');
    }
    
    return { token: generateToken(req.user) };
  }
}`
    };

    const content = mockFiles[path] || `// ${path}\n// File not found in mock data`;
    const lines = content.split('\n');
    const selectedLines = lines.slice(
      startLine - 1, 
      endLine ? endLine : lines.length
    );

    return selectedLines.join('\n');
  }

  async handleSearch(params) {
    const { query, includePattern = '**/*' } = params;
    
    console.log(`   Searching for "${query}" in ${includePattern}...`);
    await sleep(150);

    // Simulate search results
    const mockResults = {
      'authenticate': [
        'auth.ts:15 - export function authenticate(user: string, password: string)',
        'auth.test.ts:8 - describe(\'authenticate\', () => {',
        'auth.service.ts:22 - const isAuthenticated = await authenticate(req.user, req.password)'
      ],
      'password': [
        'auth.ts:15 - export function authenticate(user: string, password: string)',
        'auth.ts:17 - if (!user || !password) {',
        'auth.service.ts:22 - await authenticate(req.user, req.password)'
      ]
    };

    const results = mockResults[query] || [`No results found for "${query}"`];
    return `Found ${results.length} matches:\n${results.map((r, i) => `${i + 1}. ${r}`).join('\n')}`;
  }

  async handleWriteFile(params) {
    const { path, content } = params;
    
    console.log(`   Writing ${content.length} bytes to ${path}...`);
    await sleep(100);

    // In real implementation, would write to disk
    return `Successfully wrote to ${path}\n${content.split('\n').length} lines, ${content.length} bytes`;
  }
}

// ============================================================================
// Agent with Tool Support
// ============================================================================

class AgentWithTools {
  constructor(toolSystem) {
    this.toolSystem = toolSystem;
    this.sessions = new Map();
  }

  async ensureSession(input) {
    const { sessionKey } = input;

    if (!this.sessions.has(sessionKey)) {
      this.sessions.set(sessionKey, {
        messages: [],
        createdAt: new Date()
      });
    }

    return {
      sessionKey,
      backend: input.agent,
      runtimeSessionName: `session-${sessionKey.split(':').pop()}`
    };
  }

  /**
   * Run a turn that uses tools
   */
  async *runTurn(input) {
    const { handle, text } = input;
    const session = this.sessions.get(handle.sessionKey);

    session.messages.push({
      role: 'user',
      content: text,
      timestamp: new Date()
    });

    // Parse user intent and decide which tools to use
    const toolSequence = this.planToolUse(text);

    let assistantResponse = '';

    // Execute planned tools
    for (const toolPlan of toolSequence) {
      // Initial response
      if (toolPlan.initialMessage) {
        yield { type: 'text_delta', text: toolPlan.initialMessage, stream: 'output' };
        assistantResponse += toolPlan.initialMessage;
        await sleep(100);
      }

      // Announce tool call
      yield {
        type: 'tool_call',
        text: `Using ${toolPlan.toolName}`,
        toolCallId: toolPlan.id,
        status: 'running',
        title: `${toolPlan.toolName}: ${JSON.stringify(toolPlan.params)}`
      };

      // Execute tool
      const toolResult = await this.toolSystem.executeTool(
        toolPlan.toolName,
        toolPlan.params
      );

      // Report completion
      yield {
        type: 'tool_call',
        text: toolResult.success ? 'Tool completed' : 'Tool failed',
        toolCallId: toolPlan.id,
        status: toolResult.success ? 'success' : 'error',
        title: `${toolPlan.toolName}`
      };

      // Process result
      if (toolPlan.responseTemplate) {
        const response = toolPlan.responseTemplate(toolResult);
        yield { type: 'text_delta', text: response, stream: 'output' };
        assistantResponse += response;
      }

      await sleep(150);
    }

    // Final message
    const finalMessage = '\n✨ Task complete!\n';
    yield { type: 'text_delta', text: finalMessage, stream: 'output' };
    assistantResponse += finalMessage;

    session.messages.push({
      role: 'assistant',
      content: assistantResponse,
      timestamp: new Date()
    });

    yield { type: 'done', stopReason: 'end_turn' };
  }

  /**
   * Plan which tools to use based on user request
   * (In real implementation, the LLM decides this)
   */
  planToolUse(text) {
    const lower = text.toLowerCase();

    if (lower.includes('check') && lower.includes('auth')) {
      return [{
        id: 'call_1',
        toolName: 'read_file',
        params: { path: 'auth.ts', startLine: 1, endLine: 25 },
        initialMessage: 'Let me check that file for you...\n\n',
        responseTemplate: (result) => 
          `\n📄 Here's what I found:\n${result.content}\n\nThe authenticate function validates user credentials and throws an error if they're missing.\n`
      }];
    }

    if (lower.includes('find') && lower.includes('authenticate')) {
      return [{
        id: 'call_1',
        toolName: 'search',
        params: { query: 'authenticate', includePattern: '**/*.ts' },
        initialMessage: 'Searching for all uses of authenticate...\n\n',
        responseTemplate: (result) =>
          `\n🔍 Search results:\n${result.content}\n\nI found 3 usages across the codebase.\n`
      }];
    }

    if (lower.includes('add error logging')) {
      return [
        {
          id: 'call_1',
          toolName: 'read_file',
          params: { path: 'auth.ts' },
          initialMessage: 'Reading the current file...\n\n',
          responseTemplate: () => '✓ Read current content\n'
        },
        {
          id: 'call_2',
          toolName: 'write_file',
          params: {
            path: 'auth.ts',
            content: '// Updated code with error logging...'
          },
          initialMessage: 'Writing updated content...\n\n',
          responseTemplate: (result) =>
            `✓ ${result.content}\n\nI've added comprehensive error logging to the authenticate function.\n`
        }
      ];
    }

    // Default: just respond
    return [{
      id: 'call_1',
      toolName: 'search',
      params: { query: text.split(' ')[0] },
      initialMessage: 'Let me help you with that...\n\n',
      responseTemplate: (result) => `\n${result.content}\n`
    }];
  }
}

// ============================================================================
// Demo
// ============================================================================

async function demonstrateToolCalls() {
  console.log('');
  console.log('='.repeat(80));
  console.log('🔧 ACP Example 3: Agent Tool Calls');
  console.log('='.repeat(80));
  console.log('');

  const toolSystem = new ToolSystem();
  const agent = new AgentWithTools(toolSystem);

  // Create a session
  const handle = await agent.ensureSession({
    sessionKey: 'agent:main:demo:tools',
    agent: 'tool-demo-agent'
  });

  console.log('');

  // ===== Scenario 1: Read file =====
  console.log('📍 SCENARIO 1: Reading a file');
  console.log('-'.repeat(80));
  console.log('💬 User: Can you check the authenticate function in auth.ts?');
  console.log('');

  for await (const event of agent.runTurn({
    handle,
    text: 'Can you check the authenticate function in auth.ts?',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      process.stdout.write(event.text);
    }
  }

  console.log('');

  // ===== Scenario 2: Search =====
  console.log('📍 SCENARIO 2: Searching the codebase');
  console.log('-'.repeat(80));
  console.log('💬 User: Find all places where authenticate is used');
  console.log('');

  for await (const event of agent.runTurn({
    handle,
    text: 'Find all places where authenticate is used',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      process.stdout.write(event.text);
    }
  }

  console.log('');

  // ===== Scenario 3: Multiple tools =====
  console.log('📍 SCENARIO 3: Chaining multiple tools');
  console.log('-'.repeat(80));
  console.log('💬 User: Add error logging to the authenticate function');
  console.log('');

  for await (const event of agent.runTurn({
    handle,
    text: 'Add error logging to the authenticate function',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      process.stdout.write(event.text);
    }
  }

  console.log('');

  // ===== Summary =====
  console.log('='.repeat(80));
  console.log('🎉 Demo Complete!');
  console.log('='.repeat(80));
  console.log('');
  console.log('Key Concepts Demonstrated:');
  console.log('  ✓ Tool registration and discovery');
  console.log('  ✓ Tool call lifecycle (request → execute → result)');
  console.log('  ✓ Chaining multiple tools together');
  console.log('  ✓ Streaming tool progress to user');
  console.log('  ✓ Error handling in tools');
  console.log('');
  console.log('Available tools in this demo:');
  const tools = toolSystem.listTools();
  tools.forEach(tool => {
    console.log(`  • ${tool.name}${tool.dangerous ? ' ⚠️' : ''} - ${tool.description}`);
  });
  console.log('');
  console.log('Next: Check out Example 4 to see everything integrated!');
  console.log('');
}

// Run the demonstration
demonstrateToolCalls().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
