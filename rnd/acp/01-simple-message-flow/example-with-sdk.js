/**
 * Example 1: Using Real @agentclientprotocol/sdk
 * 
 * This demonstrates how to use the ACTUAL SDK package to create
 * an ACP server that external agents can connect to.
 * 
 * This is much closer to how OpenClaw really works!
 */

import { Readable, Writable } from 'node:stream';
import { AgentSideConnection, ndJsonStream } from '@agentclientprotocol/sdk';

// ============================================================================
// Mock Agent Implementation (simulates what OpenClaw does)
// ============================================================================

class MockAcpGatewayAgent {
  constructor(connection) {
    this.connection = connection;
    this.sessions = new Map();
  }

  /**
   * Start handling ACP requests
   * The SDK will call these methods based on incoming ACP messages
   */
  start() {
    console.log('🚀 ACP Gateway Agent started');
    console.log('📝 Waiting for ACP requests...\n');
  }

  /**
   * Handle authentication request (optional in ACP)
   */
  async authenticate(request) {
    console.log('🔐 Authentication request received');
    return {
      authenticated: true,
      agent: {
        name: 'openclaw-demo',
        version: '1.0.0'
      }
    };
  }

  /**
   * Initialize a new agent connection
   */
  async initialize(request) {
    console.log('⚡ Initialize request received');
    console.log(`   Protocol version: ${request.protocolVersion}`);
    
    return {
      protocolVersion: request.protocolVersion,
      agent: {
        name: 'openclaw-demo',
        title: 'OpenClaw Demo Agent',
        version: '1.0.0'
      },
      capabilities: {
        tools: true,
        sessions: true
      }
    };
  }

  /**
   * Create a new session
   */
  async newSession(request) {
    const sessionId = `sess_${Date.now()}`;
    
    this.sessions.set(sessionId, {
      id: sessionId,
      mode: request.mode || 'persistent',
      messages: [],
      createdAt: new Date()
    });

    console.log(`📝 New session created: ${sessionId}`);
    console.log(`   Mode: ${request.mode || 'persistent'}`);
    
    return {
      sessionId,
      mode: request.mode || 'persistent'
    };
  }

  /**
   * List all sessions
   */
  async listSessions(request) {
    console.log('📋 List sessions request');
    
    const sessions = Array.from(this.sessions.values()).map(s => ({
      sessionId: s.id,
      mode: s.mode,
      lastActive: s.createdAt.toISOString()
    }));

    return { sessions };
  }

  /**
   * Load session history
   */
  async loadSession(request) {
    console.log(`📂 Load session: ${request.sessionId}`);
    
    const session = this.sessions.get(request.sessionId);
    
    if (!session) {
      throw new Error(`Session not found: ${request.sessionId}`);
    }

    return {
      sessionId: request.sessionId,
      mode: session.mode,
      messages: session.messages
    };
  }

  /**
   * Handle a prompt (user message)
   * This is where the magic happens!
   */
  async prompt(request) {
    const { sessionId, text } = request;
    
    console.log(`\n💬 Prompt received for session: ${sessionId}`);
    console.log(`   User: ${text}`);

    const session = this.sessions.get(sessionId);
    
    if (!session) {
      throw new Error(`Session not found: ${sessionId}`);
    }

    // Add user message to session
    session.messages.push({
      role: 'user',
      content: text,
      timestamp: new Date()
    });

    // Simulate agent "thinking"
    await this.sleep(500);

    // Send text deltas (streaming response)
    const response = `Hello! I received your message: "${text}"`;
    const words = response.split(' ');

    // Stream response word by word
    for (const word of words) {
      // Send notification (streaming text)
      await this.connection.notification('session/notification', {
        sessionId,
        type: 'text_delta',
        text: word + ' '
      });
      
      await this.sleep(100);
    }

    // Add assistant message to session
    session.messages.push({
      role: 'assistant',
      content: response,
      timestamp: new Date()
    });

    console.log(`   Agent: ${response}\n`);

    // Return final response
    return {
      text: response,
      stopReason: 'end_turn'
    };
  }

  /**
   * Cancel the current operation
   */
  async cancel(notification) {
    console.log(`🛑 Cancel notification for session: ${notification.sessionId}`);
  }

  /**
   * Set session mode
   */
  async setSessionMode(request) {
    console.log(`⚙️  Set session mode: ${request.mode}`);
    
    const session = this.sessions.get(request.sessionId);
    if (session) {
      session.mode = request.mode;
    }

    return { success: true };
  }

  /**
   * Set session config option
   */
  async setSessionConfigOption(request) {
    console.log(`⚙️  Set config: ${request.key} = ${request.value}`);
    return { success: true };
  }

  // Helper
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ============================================================================
// Create ACP Server using Real SDK
// ============================================================================

async function runAcpServer() {
  console.log('');
  console.log('='.repeat(80));
  console.log('🎯 Real ACP SDK Example - Server Mode');
  console.log('='.repeat(80));
  console.log('');
  console.log('This example uses the ACTUAL @agentclientprotocol/sdk package');
  console.log('to create an ACP server, just like OpenClaw does!');
  console.log('');
  console.log('⚠️  Note: This creates a server that waits for stdin/stdout input.');
  console.log('   In production, external agents would connect via pipes.');
  console.log('');

  // In real usage, you'd use stdin/stdout for inter-process communication
  // For this demo, we'll create mock streams and send test messages

  // Create a simple stream pair for testing
  const { readable, writable } = createMockStreams();

  // Create the ndJSON stream (this is from the SDK)
  const stream = ndJsonStream(writable, readable);

  // Create AgentSideConnection with our handler
  // The SDK will call our methods based on incoming ACP messages
  const connection = new AgentSideConnection((conn) => {
    const agent = new MockAcpGatewayAgent(conn);
    agent.start();
    return agent;
  }, stream);

  console.log('✅ ACP Server created with real SDK!');
  console.log('');
  console.log('The AgentSideConnection is now listening for ACP messages.');
  console.log('');
  console.log('In a real scenario:');
  console.log('  1. External agent (Codex/Claude) connects via stdin/stdout');
  console.log('  2. SDK handles JSON-RPC protocol automatically');
  console.log('  3. Our methods get called with parsed requests');
  console.log('  4. We can send notifications back via connection.notification()');
  console.log('');

  // Send a test sequence to demonstrate
  await sendTestSequence(readable, writable);

  console.log('');
  console.log('='.repeat(80));
  console.log('✨ Example Complete!');
  console.log('='.repeat(80));
  console.log('');
  console.log('Key SDK Components Used:');
  console.log('  ✓ AgentSideConnection - Main server-side class');
  console.log('  ✓ ndJsonStream - Protocol stream handler');
  console.log('  ✓ Automatic JSON-RPC message parsing');
  console.log('  ✓ Method dispatch to our handler');
  console.log('');
  console.log('This is the same pattern OpenClaw uses in src/acp/server.ts!');
  console.log('');
}

// ============================================================================
// Mock Streams for Testing
// ============================================================================

function createMockStreams() {
  let readCallback = null;
  let writeBuffer = [];

  const readable = new ReadableStream({
    start(controller) {
      readCallback = (data) => {
        controller.enqueue(new TextEncoder().encode(data + '\n'));
      };
    }
  });

  const writable = new WritableStream({
    write(chunk) {
      const text = new TextDecoder().decode(chunk);
      writeBuffer.push(text);
      console.log('📤 Response:', text.trim());
    }
  });

  return { 
    readable, 
    writable, 
    sendMessage: (msg) => readCallback(JSON.stringify(msg)) 
  };
}

// ============================================================================
// Test Sequence
// ============================================================================

async function sendTestSequence(readable, writable) {
  // Get the send function
  const mockStreams = createMockStreams();
  const sendMessage = mockStreams.sendMessage;

  console.log('📨 Sending test ACP messages...\n');
  
  await sleep(500);

  // 1. Initialize
  console.log('1️⃣  Sending: initialize');
  sendMessage({
    jsonrpc: '2.0',
    method: 'session/initialize',
    params: { protocolVersion: '0.1.0' },
    id: 1
  });

  await sleep(1000);

  // 2. Create new session
  console.log('\n2️⃣  Sending: new session');
  sendMessage({
    jsonrpc: '2.0',
    method: 'session/new',
    params: { mode: 'persistent' },
    id: 2
  });

  await sleep(1000);

  // 3. Send prompt
  console.log('\n3️⃣  Sending: prompt');
  sendMessage({
    jsonrpc: '2.0',
    method: 'session/prompt',
    params: {
      sessionId: 'sess_test',
      text: 'Hello from the real SDK!'
    },
    id: 3
  });

  await sleep(2000);
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================================================
// Run the demo
// ============================================================================

runAcpServer().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
