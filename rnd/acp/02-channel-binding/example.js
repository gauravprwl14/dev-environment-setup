/**
 * Example 2: Channel & Thread Bindings
 * 
 * This demonstrates how OpenClaw routes messages from different
 * channels (Discord, Telegram, Slack) to the correct ACP sessions.
 * 
 * Key concepts:
 * 1. Binding Manager - routes conversations to sessions
 * 2. Persistent Bindings - from config, survive restarts
 * 3. Dynamic Bindings - created at runtime (/acp spawn)
 * 4. Session Keys - deterministic mapping
 */

import crypto from 'crypto';

// ============================================================================
// Binding Manager - Routes channels to sessions
// ============================================================================

class BindingManager {
  constructor() {
    // All active bindings
    this.bindings = new Map();
    // Separate tracking for persistent (config-based) bindings
    this.persistentBindings = new Set();
  }

  /**
   * Add a persistent binding from config
   * These survive restarts
   */
  addPersistentBinding(spec) {
    const {
      channel,      // e.g., "discord", "telegram"
      accountId,    // e.g., "bot-123"
      conversationId, // e.g., "channel-dev"
      agentId = 'main',
      mode = 'persistent',
      backend = 'codex',
      label
    } = spec;

    const bindingId = this.createBindingId({ channel, accountId, conversationId });
    const sessionKey = this.createSessionKey({ channel, accountId, conversationId, agentId });

    const binding = {
      id: bindingId,
      conversation: { channel, accountId, conversationId },
      targetSessionKey: sessionKey,
      mode,
      backend,
      label,
      source: 'config',
      boundAt: Date.now()
    };

    this.bindings.set(bindingId, binding);
    this.persistentBindings.add(bindingId);

    console.log(`✅ Added persistent binding: ${bindingId}`);
    console.log(`   → Session: ${sessionKey}`);
    console.log(`   → Backend: ${backend} (${mode} mode)`);
    if (label) console.log(`   → Label: ${label}`);

    return binding;
  }

  /**
   * Create a dynamic binding (runtime)
   * Like when user says "/acp spawn codex --thread"
   */
  createDynamicBinding(spec) {
    const {
      channel,
      accountId,
      conversationId,
      agentId = 'main',
      mode = 'persistent',
      backend,
      label
    } = spec;

    const bindingId = this.createBindingId({ channel, accountId, conversationId });
    const sessionKey = this.createSessionKey({ channel, accountId, conversationId, agentId });

    const binding = {
      id: bindingId,
      conversation: { channel, accountId, conversationId },
      targetSessionKey: sessionKey,
      mode,
      backend,
      label,
      source: 'dynamic',
      boundAt: Date.now()
    };

    this.bindings.set(bindingId, binding);

    console.log(`✅ Created dynamic binding: ${bindingId}`);
    console.log(`   → Session: ${sessionKey}`);
    console.log(`   → Backend: ${backend} (${mode} mode)`);
    if (label) console.log(`   → Label: ${label}`);

    return binding;
  }

  /**
   * Resolve where a message should go
   * This is called for every incoming message
   */
  resolveBinding(channel, accountId, conversationId) {
    const bindingId = this.createBindingId({ channel, accountId, conversationId });
    const binding = this.bindings.get(bindingId);

    if (binding) {
      console.log(`✅ Found binding for ${bindingId}`);
      console.log(`   → Routing to session: ${binding.targetSessionKey}`);
      console.log(`   → Using backend: ${binding.backend}`);
      console.log(`   → Source: ${binding.source}`);
    } else {
      console.log(`❌ No binding found for ${bindingId}`);
    }

    return binding;
  }

  /**
   * Remove a binding (like when thread is closed)
   */
  removeBinding(channel, accountId, conversationId) {
    const bindingId = this.createBindingId({ channel, accountId, conversationId });
    const binding = this.bindings.get(bindingId);

    if (!binding) {
      return false;
    }

    // Don't remove persistent bindings
    if (this.persistentBindings.has(bindingId)) {
      console.log(`❌ Cannot remove persistent binding: ${bindingId}`);
      return false;
    }

    this.bindings.delete(bindingId);
    console.log(`✅ Removed dynamic binding: ${bindingId}`);
    return true;
  }

  /**
   * List all active bindings
   */
  listBindings() {
    return Array.from(this.bindings.values());
  }

  /**
   * Create a unique binding ID from conversation details
   */
  createBindingId({ channel, accountId, conversationId }) {
    return `${channel}:${accountId}:${conversationId}`;
  }

  /**
   * Create a session key
   * Format: agent:<agentId>:acp:<channel>:<hash>
   */
  createSessionKey({ channel, accountId, conversationId, agentId }) {
    const hash = this.hashConversation({ channel, accountId, conversationId });
    return `agent:${agentId}:acp:${channel}:${hash}`;
  }

  /**
   * Hash conversation details to create stable session identifiers
   */
  hashConversation({ channel, accountId, conversationId }) {
    const str = `${channel}:${accountId}:${conversationId}`;
    return crypto
      .createHash('sha256')
      .update(str)
      .digest('hex')
      .substring(0, 8);
  }
}

// ============================================================================
// Simple Agent (from Example 1)
// ============================================================================

class SimpleAgent {
  constructor() {
    this.sessions = new Map();
  }

  async ensureSession(input) {
    const { sessionKey, agent, mode, cwd } = input;

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
      runtimeSessionName: `session-${sessionKey.split(':').pop()}`,
      cwd: cwd || process.cwd()
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

    const response = `Received in ${handle.backend}: "${text}"`;
    
    yield { type: 'text_delta', text: response };
    
    session.messages.push({
      role: 'assistant',
      content: response,
      timestamp: new Date()
    });

    yield { type: 'done', stopReason: 'end_turn' };
  }
}

// ============================================================================
// Demo: Show routing in action
// ============================================================================

async function demonstrateChannelBinding() {
  console.log('');
  console.log('='.repeat(80));
  console.log('🔗 ACP Example 2: Channel & Thread Bindings');
  console.log('='.repeat(80));
  console.log('');

  const bindingManager = new BindingManager();
  const agent = new SimpleAgent();

  // ===== Step 1: Set up persistent bindings (from config) =====
  console.log('📍 STEP 1: Setting up persistent bindings (from config)');
  console.log('-'.repeat(80));
  console.log('');

  // Binding for Discord #dev channel
  bindingManager.addPersistentBinding({
    channel: 'discord',
    accountId: 'bot-123',
    conversationId: 'channel-dev',
    agentId: 'main',
    backend: 'codex',
    mode: 'persistent',
    label: 'Dev Channel Bot'
  });
  console.log('');

  // Binding for Telegram team chat
  bindingManager.addPersistentBinding({
    channel: 'telegram',
    accountId: 'bot-456',
    conversationId: 'group-team',
    agentId: 'main',
    backend: 'claude',
    mode: 'persistent',
    label: 'Team Chat Assistant'
  });
  console.log('');

  // ===== Step 2: Message from Discord =====
  console.log('📍 STEP 2: Incoming message from Discord #dev');
  console.log('-'.repeat(80));
  console.log('');

  console.log('📨 User in Discord #dev says: "Hey bot, can you help?"');
  console.log('');
  console.log('🔍 Looking up binding...');
  
  const discordBinding = bindingManager.resolveBinding(
    'discord',
    'bot-123',
    'channel-dev'
  );
  console.log('');

  if (discordBinding) {
    console.log('💬 Routing message to agent...');
    const handle = await agent.ensureSession({
      sessionKey: discordBinding.targetSessionKey,
      agent: discordBinding.backend,
      mode: discordBinding.mode
    });

    for await (const event of agent.runTurn({
      handle,
      text: 'Hey bot, can you help?',
      mode: 'prompt'
    })) {
      if (event.type === 'text_delta') {
        console.log(`   Agent: ${event.text}`);
      }
    }
  }
  console.log('');

  // ===== Step 3: Message from Telegram =====
  console.log('📍 STEP 3: Incoming message from Telegram team chat');
  console.log('-'.repeat(80));
  console.log('');

  console.log('📨 User in Telegram says: "What\'s the status?"');
  console.log('');
  console.log('🔍 Looking up binding...');
  
  const telegramBinding = bindingManager.resolveBinding(
    'telegram',
    'bot-456',
    'group-team'
  );
  console.log('');

  if (telegramBinding) {
    console.log('💬 Routing message to agent...');
    const handle = await agent.ensureSession({
      sessionKey: telegramBinding.targetSessionKey,
      agent: telegramBinding.backend,
      mode: telegramBinding.mode
    });

    for await (const event of agent.runTurn({
      handle,
      text: "What's the status?",
      mode: 'prompt'
    })) {
      if (event.type === 'text_delta') {
        console.log(`   Agent: ${event.text}`);
      }
    }
  }
  console.log('');

  // ===== Step 4: Create dynamic binding (like /acp spawn) =====
  console.log('📍 STEP 4: Creating dynamic binding (user runs /acp spawn)');
  console.log('-'.repeat(80));
  console.log('');

  console.log('📨 User in Discord thread says: "/acp spawn claude --thread"');
  console.log('');

  // Simulate the spawn command
  const threadBinding = bindingManager.createDynamicBinding({
    channel: 'discord',
    accountId: 'bot-123',
    conversationId: 'thread-bug-123',
    agentId: 'main',
    backend: 'claude',
    mode: 'persistent',
    label: 'Bug 123 Investigation'
  });
  console.log('');

  console.log('💬 Now messages in this thread go to dedicated session...');
  const threadHandle = await agent.ensureSession({
    sessionKey: threadBinding.targetSessionKey,
    agent: threadBinding.backend,
    mode: threadBinding.mode
  });

  for await (const event of agent.runTurn({
    handle: threadHandle,
    text: 'Analyze the authentication bug',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      console.log(`   Agent: ${event.text}`);
    }
  }
  console.log('');

  // ===== Step 5: List all bindings =====
  console.log('📍 STEP 5: Viewing all active bindings');
  console.log('-'.repeat(80));
  console.log('');

  const allBindings = bindingManager.listBindings();
  console.log(`Found ${allBindings.length} active bindings:\n`);

  allBindings.forEach((binding, index) => {
    console.log(`${index + 1}. [${binding.source}] ${binding.id}`);
    console.log(`   Target: ${binding.targetSessionKey}`);
    console.log(`   Backend: ${binding.backend} (${binding.mode})`);
    if (binding.label) console.log(`   Label: ${binding.label}`);
    console.log('');
  });

  // ===== Step 6: Remove dynamic binding =====
  console.log('📍 STEP 6: Cleaning up dynamic binding');
  console.log('-'.repeat(80));
  console.log('');

  console.log('🗑️  Thread closed, removing dynamic binding...');
  bindingManager.removeBinding('discord', 'bot-123', 'thread-bug-123');
  console.log('');

  console.log('Remaining bindings:');
  const remainingBindings = bindingManager.listBindings();
  console.log(`  ${remainingBindings.length} bindings (persistent bindings remain)`);
  console.log('');

  // ===== Summary =====
  console.log('='.repeat(80));
  console.log('🎉 Demo Complete!');
  console.log('='.repeat(80));
  console.log('');
  console.log('Key Concepts Demonstrated:');
  console.log('  ✓ Persistent bindings from config');
  console.log('  ✓ Dynamic bindings created at runtime');
  console.log('  ✓ Binding resolution (routing messages)');
  console.log('  ✓ Session key generation (deterministic hashing)');
  console.log('  ✓ Multiple channels coexisting');
  console.log('  ✓ Binding cleanup');
  console.log('');
  console.log('Real-world use cases:');
  console.log('  • Team channels with persistent agents');
  console.log('  • Per-thread support sessions');
  console.log('  • Multi-account routing');
  console.log('');
  console.log('Next: Check out Example 3 to learn about session management!');
  console.log('');
}

// Run the demonstration
demonstrateChannelBinding().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
