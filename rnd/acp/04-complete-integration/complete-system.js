/**
 * Complete ACP Integration Example
 * 
 * This brings together all concepts from Examples 1-3:
 * - Message flow (Example 1)
 * - Channel bindings (Example 2)
 * - Tool calls (Example 3)
 * 
 * Simulates a realistic multi-channel, multi-user system.
 */

import crypto from 'crypto';

// ============================================================================
// Helper
// ============================================================================

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================================================
// ALL COMPONENTS INTEGRATED
// ============================================================================

// 1. Tool System (from Example 3)
class ToolSystem {
  constructor() {
    this.tools = new Map();
    this.tools.set('read_file', {
      name: 'read_file',
      handler: async (params) => {
        await sleep(50);
        return `// Contents of ${params.path}\nexport function example() { /* code */ }`;
      }
    });
    this.tools.set('search', {
      name: 'search',
      handler: async (params) => {
        await sleep(50);
        return `Found 2 matches for "${params.query}"`;
      }
    });
  }

  async executeTool(toolName, params) {
    const tool = this.tools.get(toolName);
    if (!tool) throw new Error(`Unknown tool: ${toolName}`);
    
    console.log(`      🔧 Tool: ${toolName}(${JSON.stringify(params)})`);
    const result = await tool.handler(params);
    return { success: true, content: result, toolName };
  }
}

// 2. Binding Manager (from Example 2)
class BindingManager {
  constructor() {
    this.bindings = new Map();
  }

  addPersistentBinding(spec) {
    const bindingId = `${spec.channel}:${spec.accountId}:${spec.conversationId}`;
    const sessionKey = this.createSessionKey(spec);
    
    this.bindings.set(bindingId, {
      id: bindingId,
      conversation: { channel: spec.channel, accountId: spec.accountId, conversationId: spec.conversationId },
      targetSessionKey: sessionKey,
      mode: spec.mode,
      backend: spec.backend,
      label: spec.label,
      source: 'config'
    });
    
    return this.bindings.get(bindingId);
  }

  createDynamicBinding(spec) {
    const bindingId = `${spec.channel}:${spec.accountId}:${spec.conversationId}`;
    const sessionKey = this.createSessionKey(spec);
    
    this.bindings.set(bindingId, {
      id: bindingId,
      conversation: { channel: spec.channel, accountId: spec.accountId, conversationId: spec.conversationId },
      targetSessionKey: sessionKey,
      mode: spec.mode,
      backend: spec.backend,
      label: spec.label,
      source: 'dynamic'
    });
    
    return this.bindings.get(bindingId);
  }

  resolveBinding(channel, accountId, conversationId) {
    const bindingId = `${channel}:${accountId}:${conversationId}`;
    return this.bindings.get(bindingId);
  }

  createSessionKey({ channel, accountId, conversationId, agentId = 'main' }) {
    const hash = crypto.createHash('sha256')
      .update(`${channel}:${accountId}:${conversationId}`)
      .digest('hex')
      .substring(0, 8);
    return `agent:${agentId}:acp:${channel}:${hash}`;
  }
}

// 3. Agent Runtime (from Example 1, enhanced with tools)
class AgentRuntime {
  constructor(toolSystem) {
    this.toolSystem = toolSystem;
    this.sessions = new Map();
  }

  async ensureSession(input) {
    const { sessionKey, agent, mode } = input;
    
    if (!this.sessions.has(sessionKey)) {
      this.sessions.set(sessionKey, {
        messages: [],
        createdAt: new Date(),
        mode
      });
    }
    
    return {
      sessionKey,
      backend: agent,
      runtimeSessionName: `session-${sessionKey.split(':').pop()}`
    };
  }

  async *runTurn(input) {
    const { handle, text } = input;
    const session = this.sessions.get(handle.sessionKey);
    
    session.messages.push({
      role: 'user',
      content: text,
      timestamp: new Date()
    });

    // Simulate agent thinking
    yield { type: 'text_delta', text: 'Thinking...\n', stream: 'thought' };
    await sleep(100);

    // Agent decides to use a tool (simulated)
    const needsTool = text.toLowerCase().includes('file') || text.toLowerCase().includes('search');
    
    if (needsTool) {
      const toolName = text.toLowerCase().includes('file') ? 'read_file' : 'search';
      const params = toolName === 'read_file' 
        ? { path: 'example.ts' }
        : { query: 'authenticate' };

      yield {
        type: 'tool_call',
        text: `Using ${toolName}`,
        toolCallId: 'call_1',
        status: 'running',
        title: toolName
      };

      const toolResult = await this.toolSystem.executeTool(toolName, params);

      yield {
        type: 'tool_call',
        text: 'Tool completed',
        toolCallId: 'call_1',
        status: 'success'
      };

      yield {
        type: 'text_delta',
        text: `Based on the ${toolName} result: ${toolResult.content.substring(0, 50)}...\n`,
        stream: 'output'
      };
    } else {
      yield {
        type: 'text_delta',
        text: `Got your message: "${text}"\n`,
        stream: 'output'
      };
    }

    yield {
      type: 'done',
      stopReason: 'end_turn'
    };

    session.messages.push({
      role: 'assistant',
      content: `Processed: ${text}`,
      timestamp: new Date()
    });
  }

  async close(handle) {
    this.sessions.delete(handle.sessionKey);
  }
}

// 4. Gateway (orchestrates everything)
class Gateway {
  constructor(bindingManager, runtime) {
    this.bindingManager = bindingManager;
    this.runtime = runtime;
  }

  async handleIncomingMessage(channel, accountId, conversationId, text, senderName = 'User') {
    console.log(`\n📨 Incoming from ${channel} (${senderName}): "${text}"`);
    
    // 1. Resolve binding
    console.log(`   🔍 Resolving binding for ${channel}:${conversationId}...`);
    const binding = this.bindingManager.resolveBinding(channel, accountId, conversationId);
    
    if (!binding) {
      console.log(`   ❌ No binding found!`);
      return;
    }
    
    console.log(`   ✅ Found ${binding.source} binding → ${binding.backend} session`);
    console.log(`      Session: ${binding.targetSessionKey}`);
    
    // 2. Ensure session
    const handle = await this.runtime.ensureSession({
      sessionKey: binding.targetSessionKey,
      agent: binding.backend,
      mode: binding.mode
    });
    
    console.log(`   💬 Processing with ${handle.backend}...`);
    
    // 3. Run turn and stream back
    console.log(`   📤 Response:`);
    let fullResponse = '';
    
    for await (const event of this.runtime.runTurn({ handle, text, mode: 'prompt' })) {
      if (event.type === 'text_delta') {
        const cleanText = event.text;
        fullResponse += cleanText;
        process.stdout.write(`      ${cleanText}`);
      } else if (event.type === 'tool_call' && event.status === 'running') {
        // Already logged by tool system
      } else if (event.type === 'done') {
        console.log(`\n   ✅ Complete!`);
      }
    }
    
    return fullResponse;
  }

  async spawnDynamicBinding(channel, accountId, conversationId, backend, label) {
    console.log(`\n🚀 Spawning dynamic ${backend} session for ${channel}:${conversationId}`);
    
    const binding = this.bindingManager.createDynamicBinding({
      channel,
      accountId,
      conversationId,
      backend,
      mode: 'persistent',
      label
    });
    
    console.log(`   ✅ Created binding → ${binding.targetSessionKey}`);
    
    return binding;
  }
}

// ============================================================================
// DEMONSTRATION
// ============================================================================

async function demonstrateCompleteSystem() {
  console.log('');
  console.log('═'.repeat(80));
  console.log('🎯 Complete ACP Integration Demo');
  console.log('═'.repeat(80));
  console.log('');
  console.log('This demonstrates a realistic multi-channel system with:');
  console.log('  • Multiple messaging channels (Discord, Telegram)');
  console.log('  • Persistent and dynamic bindings');
  console.log('  • Session management with history');
  console.log('  • Agent tool calls');
  console.log('  • Streaming responses');
  console.log('');

  // Initialize system
  const toolSystem = new ToolSystem();
  const bindingManager = new BindingManager();
  const runtime = new AgentRuntime(toolSystem);
  const gateway = new Gateway(bindingManager, runtime);

  // =====================================================================
  // SETUP: Configure persistent bindings
  // =====================================================================
  console.log('━'.repeat(80));
  console.log('⚙️  SETUP: Configuring persistent bindings');
  console.log('━'.repeat(80));
  
  console.log('\n📝 Adding persistent binding for Discord #dev-chat...');
  bindingManager.addPersistentBinding({
    channel: 'discord',
    accountId: 'bot-12345',
    conversationId: 'channel-dev',
    backend: 'codex',
    mode: 'persistent',
    label: 'Dev Team Assistant',
    agentId: 'main'
  });
  
  console.log('📝 Adding persistent binding for Telegram team chat...');
  bindingManager.addPersistentBinding({
    channel: 'telegram',
    accountId: 'bot-67890',
    conversationId: 'group-team',
    backend: 'claude',
    mode: 'persistent',
    label: 'Team Chat Bot',
    agentId: 'main'
  });

  await sleep(500);

  // =====================================================================
  // SCENARIO 1: Discord user sends message to persistent channel
  // =====================================================================
  console.log('\n');
  console.log('━'.repeat(80));
  console.log('📍 SCENARIO 1: Message to persistent Discord channel');
  console.log('━'.repeat(80));
  
  await gateway.handleIncomingMessage(
    'discord',           // channel
    'bot-12345',        // accountId
    'channel-dev',      // conversationId
    'Can you read the auth file?',
    'Alice'             // sender
  );

  await sleep(1000);

  // =====================================================================
  // SCENARIO 2: Follow-up message in same channel (uses same session)
  // =====================================================================
  console.log('\n');
  console.log('━'.repeat(80));
  console.log('📍 SCENARIO 2: Follow-up in same Discord channel');
  console.log('━'.repeat(80));
  
  await gateway.handleIncomingMessage(
    'discord',
    'bot-12345',
    'channel-dev',
    'Thanks! Now search for authenticate',
    'Alice'
  );

  await sleep(1000);

  // =====================================================================
  // SCENARIO 3: Different channel (Telegram) gets routed to different agent
  // =====================================================================
  console.log('\n');
  console.log('━'.repeat(80));
  console.log('📍 SCENARIO 3: Message to Telegram (different agent)');
  console.log('━'.repeat(80));
  
  await gateway.handleIncomingMessage(
    'telegram',
    'bot-67890',
    'group-team',
    'What is the status of the project?',
    'Bob'
  );

  await sleep(1000);

  // =====================================================================
  // SCENARIO 4: Dynamic binding (like /acp spawn)
  // =====================================================================
  console.log('\n');
  console.log('━'.repeat(80));
  console.log('📍 SCENARIO 4: User spawns dynamic agent in Discord thread');
  console.log('━'.repeat(80));
  
  console.log('\n💬 Alice in Discord thread says: /acp spawn claude --thread');
  
  await gateway.spawnDynamicBinding(
    'discord',
    'bot-12345',
    'thread-bug-fix',
    'claude',
    'Bug Fix Investigation'
  );

  await sleep(500);

  console.log('\n💬 Now messaging the thread...');
  
  await gateway.handleIncomingMessage(
    'discord',
    'bot-12345',
    'thread-bug-fix',
    'Analyze the authentication bug',
    'Alice'
  );

  await sleep(1000);

  // =====================================================================
  // SUMMARY
  // =====================================================================
  console.log('\n');
  console.log('═'.repeat(80));
  console.log('✨ Demo Complete!');
  console.log('═'.repeat(80));
  console.log('');
  console.log('What we demonstrated:');
  console.log('  ✅ Persistent bindings (config-based channel routing)');
  console.log('  ✅ Dynamic bindings (runtime-created, like /acp spawn)');
  console.log('  ✅ Multiple channels (Discord, Telegram)');
  console.log('  ✅ Multiple agents (Codex, Claude)');
  console.log('  ✅ Session persistence (follow-up messages use same history)');
  console.log('  ✅ Tool calls (read_file, search)');
  console.log('  ✅ Streaming responses');
  console.log('');
  console.log('Key Insights:');
  console.log('  • Each channel/conversation routes to a specific ACP session');
  console.log('  • Sessions maintain conversation history');
  console.log('  • Agents can use tools to perform actions');
  console.log('  • Responses stream back in real-time');
  console.log('  • Dynamic bindings allow per-thread agents');
  console.log('');
  console.log('This is exactly how OpenClaw\'s ACP system works! 🎉');
  console.log('');
  console.log('Ready to implement? Check out the ../README.md implementation guide!');
  console.log('');
}

// Run the complete system demo
demonstrateCompleteSystem().catch(error => {
  console.error('❌ Error:', error);
  console.error(error.stack);
  process.exit(1);
});
