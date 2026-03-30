/**
 * Example 1: Simple Message Flow
 * 
 * This demonstrates the core ACP concepts:
 * 1. Creating/finding a session (ensureSession)
 * 2. Sending messages (runTurn)
 * 3. Streaming responses (AsyncIterable events)
 * 4. Cleaning up (close)
 */

// ============================================================================
// Type Definitions (simplified from real ACP)
// ============================================================================

/**
 * A handle to an active session
 * Think of this as a "connection" to an ongoing conversation
 */
class SessionHandle {
  constructor(sessionKey, backend, runtimeSessionName, cwd) {
    this.sessionKey = sessionKey;
    this.backend = backend;
    this.runtimeSessionName = runtimeSessionName;
    this.cwd = cwd;
  }
}

// ============================================================================
// Simple Agent Implementation
// ============================================================================

class SimpleAgent {
  constructor() {
    // Store sessions in memory (real version saves to disk)
    this.sessions = new Map();
  }

  /**
   * Step 1: Ensure a session exists
   * 
   * @param {Object} input
   * @param {string} input.sessionKey - Unique identifier for this conversation
   * @param {string} input.agent - Which agent backend to use
   * @param {"persistent"|"oneshot"} input.mode - Keep history or not
   * @param {string} [input.cwd] - Working directory
   * @returns {SessionHandle}
   */
  async ensureSession(input) {
    const { sessionKey, agent, mode, cwd } = input;

    // Create session if it doesn't exist
    if (!this.sessions.has(sessionKey)) {
      console.log(`📝 Creating new ${mode} session: ${sessionKey}`);
      this.sessions.set(sessionKey, {
        messages: [],
        createdAt: new Date(),
        mode
      });
    } else {
      console.log(`♻️  Reusing existing session: ${sessionKey}`);
    }

    // Return a handle to reference this session
    return new SessionHandle(
      sessionKey,
      agent,
      `session-${sessionKey.split(':').pop()}`,
      cwd || process.cwd()
    );
  }

  /**
   * Step 2: Run a turn (send a message and get streaming response)
   * 
   * @param {Object} input
   * @param {SessionHandle} input.handle - Session to use
   * @param {string} input.text - The message to send
   * @param {"prompt"|"steer"} input.mode - New message or steering
   * @returns {AsyncIterable} Stream of events
   */
  async *runTurn(input) {
    const { handle, text, mode } = input;
    const sessionKey = handle.sessionKey;
    const session = this.sessions.get(sessionKey);

    console.log(`💬 Processing ${mode} in ${sessionKey}`);
    console.log(`   User said: ${text}`);

    // Add user message to history
    session.messages.push({
      role: 'user',
      content: text,
      timestamp: new Date()
    });

    // Simulate agent "thinking" and responding with streaming
    // This mimics how real agents send back partial responses

    // Build response word by word to simulate streaming
    const words = ['Hello!', 'I', 'received', 'your', 'message:', `"${text}"`];
    let fullResponse = '';

    for (const word of words) {
      yield {
        type: 'text_delta',
        text: word + ' ',
        stream: 'output'
      };
      fullResponse += word + ' ';
      await this.sleep(150);  // Simulate processing time
    }

    // Add complete response to history
    session.messages.push({
      role: 'assistant',
      content: fullResponse.trim(),
      timestamp: new Date()
    });

    console.log(`   Agent said: ${fullResponse.trim()}`);

    // Signal completion
    yield {
      type: 'done',
      stopReason: 'end_turn'
    };
  }

  /**
   * Cancel an ongoing turn
   */
  async cancel(handle, reason) {
    console.log(`🛑 Cancelling session: ${handle.sessionKey} (${reason})`);
  }

  /**
   * Close and cleanup a session
   */
  async close(handle, reason) {
    console.log(`👋 Closing session: ${handle.sessionKey} (${reason})`);
    this.sessions.delete(handle.sessionKey);
  }

  /**
   * Helper: Sleep for ms milliseconds
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Helper: Get session history (for debugging)
   */
  getSessionHistory(sessionKey) {
    return this.sessions.get(sessionKey);
  }
}

// ============================================================================
// Demo: Show the flow in action
// ============================================================================

async function demonstrateSimpleFlow() {
  console.log('');
  console.log('='.repeat(70));
  console.log('🚀 ACP Example 1: Simple Message Flow');
  console.log('='.repeat(70));
  console.log('');

  const agent = new SimpleAgent();

  // ===== Step 1: Create a session =====
  console.log('📍 STEP 1: Creating a session');
  console.log('-'.repeat(70));
  
  const handle = await agent.ensureSession({
    sessionKey: 'agent:main:demo:user123',  // Unique key for this conversation
    agent: 'simple-demo-agent',             // Which agent to use
    mode: 'persistent'                      // Keep history between messages
  });
  
  console.log('✅ Session handle obtained:');
  console.log(`   Key: ${handle.sessionKey}`);
  console.log(`   Backend: ${handle.backend}`);
  console.log('');

  // ===== Step 2: Send first message =====
  console.log('📍 STEP 2: Sending first message');
  console.log('-'.repeat(70));
  
  let response1 = '';
  process.stdout.write('   Streaming response: ');
  
  for await (const event of agent.runTurn({
    handle,
    text: 'Hello Agent!',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      response1 += event.text;
      process.stdout.write(event.text);  // Show live streaming
    } else if (event.type === 'done') {
      console.log('');
      console.log(`✅ Message complete! Stop reason: ${event.stopReason}`);
    }
  }
  console.log('');

  // ===== Step 3: Send follow-up message (uses same session) =====
  console.log('📍 STEP 3: Sending follow-up message');
  console.log('-'.repeat(70));
  
  let response2 = '';
  process.stdout.write('   Streaming response: ');
  
  for await (const event of agent.runTurn({
    handle,
    text: 'Can you help me write TypeScript?',
    mode: 'prompt'
  })) {
    if (event.type === 'text_delta') {
      response2 += event.text;
      process.stdout.write(event.text);
    } else if (event.type === 'done') {
      console.log('');
      console.log(`✅ Follow-up complete! Stop reason: ${event.stopReason}`);
    }
  }
  console.log('');

  // ===== Step 4: Check session history =====
  console.log('📍 STEP 4: Checking session history');
  console.log('-'.repeat(70));
  
  const history = agent.getSessionHistory(handle.sessionKey);
  console.log(`Total messages in session: ${history.messages.length}`);
  console.log('Message history:');
  history.messages.forEach((msg, i) => {
    console.log(`   ${i + 1}. [${msg.role}]: ${msg.content.substring(0, 50)}...`);
  });
  console.log('');

  // ===== Step 5: Close session =====
  console.log('📍 STEP 5: Closing session');
  console.log('-'.repeat(70));
  
  await agent.close(handle, 'demo complete');
  console.log('✅ Session cleaned up!');
  console.log('');

  // ===== Summary =====
  console.log('='.repeat(70));
  console.log('🎉 Demo Complete!');
  console.log('='.repeat(70));
  console.log('');
  console.log('Key Concepts Demonstrated:');
  console.log('  ✓ Session creation (ensureSession)');
  console.log('  ✓ Message streaming (runTurn with AsyncIterable)');
  console.log('  ✓ Session persistence (multiple messages in same session)');
  console.log('  ✓ Event types (text_delta, done)');
  console.log('  ✓ Session cleanup (close)');
  console.log('');
  console.log('Next: Check out Example 2 to learn about channel bindings!');
  console.log('');
}

// Run the demonstration
demonstrateSimpleFlow().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
