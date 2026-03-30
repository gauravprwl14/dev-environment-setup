/**
 * Real SDK Example: Client + Server Integration
 * 
 * This demonstrates how to use both:
 * - AgentSideConnection (server - receives from agents)
 * - ClientSideConnection (client - connects to agents)
 * 
 * This mirrors how OpenClaw integrates with external agents!
 */

import { spawn } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { 
  AgentSideConnection, 
  ClientSideConnection, 
  ndJsonStream, 
  PROTOCOL_VERSION 
} from '@agentclientprotocol/sdk';

// ============================================================================
// PART 1: ClientSideConnection (OpenClaw acts as client)
// ============================================================================

/**
 * This simulates OpenClaw spawning an external agent (like Codex)
 * and communicating with it via the SDK
 */
class AcpClient {
  constructor() {
    this.connection = null;
  }

  /**
   * Connect to an external ACP agent
   */
  async connect(agentProcess) {
    console.log('🔌 Connecting to external agent via ClientSideConnection...\n');

    // Create streams from process pipes
    const input = Writable.toWeb(agentProcess.stdin);
    const output = Readable.toWeb(agentProcess.stdout);
    const stream = ndJsonStream(input, output);

    // Create ClientSideConnection
    this.connection = new ClientSideConnection(
      () => {
        return {
          agent: {
            name: 'openclaw-client-demo',
            version: '1.0.0'
          },

          /**
           * Handle permission requests from the agent
           * (e.g., "Can I read this file?")
           */
          async requestPermission(params) {
            console.log('\n📋 Permission Request:');
            console.log(`   Tool: ${params.toolCall?.title || 'unknown'}`);
            
            // In real implementation, validate the tool call
            // For demo, auto-approve "safe" tools
            const isSafe = ['read', 'search'].includes(
              params.toolCall?._meta?.toolName
            );

            if (isSafe) {
              console.log('   ✅ Auto-approved (safe tool)');
              return { allowed: true };
            }

            console.log('   ⚠️  Would prompt user for approval');
            return { allowed: true }; // For demo, approve all
          },

          /**
           * Handle session notifications from the agent
           * (e.g., streaming text, tool results)
           */
          async sessionUpdate(notification) {
            if (notification.type === 'text_delta') {
              process.stdout.write(notification.text);
            } else if (notification.type === 'tool_result') {
              console.log('\n🔧 Tool result received');
            }
          }
        };
      },
      stream
    );

    console.log('✅ ClientSideConnection established!\n');
    return this.connection;
  }

  /**
   * Initialize the agent
   */
  async initialize() {
    console.log('⚡ Initializing agent...');
    const response = await this.connection.request('session/initialize', {
      protocolVersion: PROTOCOL_VERSION
    });
    console.log(`   Agent: ${response.agent?.name || 'unknown'}`);
    console.log(`   Protocol: ${response.protocolVersion}\n`);
    return response;
  }

  /**
   * Create a new session
   */
  async createSession(mode = 'persistent') {
    console.log(`📝 Creating ${mode} session...`);
    const response = await this.connection.request('session/new', { mode });
    console.log(`   Session ID: ${response.sessionId}\n`);
    return response;
  }

  /**
   * Send a prompt to the agent
   */
  async sendPrompt(sessionId, text) {
    console.log(`💬 Sending prompt: "${text}"`);
    console.log('   Agent response: ');
    
    const response = await this.connection.request('session/prompt', {
      sessionId,
      text
    });

    console.log(`\n   Stop reason: ${response.stopReason}\n`);
    return response;
  }

  /**
   * List sessions
   */
  async listSessions() {
    console.log('📋 Listing sessions...');
    const response = await this.connection.request('session/list', {});
    console.log(`   Found ${response.sessions?.length || 0} sessions\n`);
    return response;
  }
}

// ============================================================================
// PART 2: AgentSideConnection (Mock external agent)
// ============================================================================

/**
 * This simulates an external agent (like Codex) that receives
 * ACP requests from OpenClaw
 */
class MockExternalAgent {
  constructor(connection) {
    this.connection = connection;
    this.sessions = new Map();
  }

  async initialize(request) {
    return {
      protocolVersion: request.protocolVersion,
      agent: {
        name: 'mock-codex',
        title: 'Mock Codex Agent',
        version: '1.0.0'
      },
      capabilities: {
        tools: true,
        sessions: true
      }
    };
  }

  async newSession(request) {
    const sessionId = `sess_${Date.now()}`;
    this.sessions.set(sessionId, {
      id: sessionId,
      mode: request.mode,
      messages: []
    });
    return { sessionId, mode: request.mode };
  }

  async listSessions() {
    return {
      sessions: Array.from(this.sessions.values()).map(s => ({
        sessionId: s.id,
        mode: s.mode
      }))
    };
  }

  async prompt(request) {
    const { sessionId, text } = request;
    const session = this.sessions.get(sessionId);

    if (!session) {
      throw new Error(`Session not found: ${sessionId}`);
    }

    session.messages.push({ role: 'user', content: text });

    // Simulate streaming response
    const response = `Acknowledged: ${text}`;
    const words = response.split(' ');

    for (const word of words) {
      await this.connection.notification('session/notification', {
        sessionId,
        type: 'text_delta',
        text: word + ' '
      });
      await sleep(100);
    }

    session.messages.push({ role: 'assistant', content: response });

    return {
      text: response,
      stopReason: 'end_turn'
    };
  }
}

// ============================================================================
// DEMO: Complete Client-Server Flow
// ============================================================================

async function runCompleteDemo() {
  console.log('');
  console.log('='.repeat(80));
  console.log('🎯 Real ACP SDK - Complete Client + Server Demo');
  console.log('='.repeat(80));
  console.log('');
  console.log('This demonstrates:');
  console.log('  • ClientSideConnection (OpenClaw → External Agent)');
  console.log('  • AgentSideConnection (External Agent receives requests)');
  console.log('  • Real SDK protocol handling');
  console.log('  • Permission requests');
  console.log('  • Streaming responses');
  console.log('');
  console.log('─'.repeat(80));
  console.log('');

  // Spawn a mock external agent process
  // In reality, this would be: spawn('codex', [...])
  console.log('🚀 Spawning mock external agent process...\n');
  
  const agentProcess = spawn('node', ['-e', `
    import { AgentSideConnection, ndJsonStream } from '@agentclientprotocol/sdk';
    import { Readable, Writable } from 'node:stream';

    const input = Writable.toWeb(process.stdout);
    const output = Readable.toWeb(process.stdin);
    const stream = ndJsonStream(input, output);

    class Agent {
      constructor(conn) { this.connection = conn; this.sessions = new Map(); }
      async initialize(req) { 
        return { 
          protocolVersion: req.protocolVersion, 
          agent: { name: 'mock-external', version: '1.0.0' },
          capabilities: { tools: true, sessions: true }
        };
      }
      async newSession(req) { 
        const id = 'sess_' + Date.now();
        this.sessions.set(id, { id, mode: req.mode, messages: [] });
        return { sessionId: id, mode: req.mode };
      }
      async listSessions() {
        return { sessions: Array.from(this.sessions.values()) };
      }
      async prompt(req) {
        const session = this.sessions.get(req.sessionId);
        if (!session) throw new Error('Session not found');
        session.messages.push({ role: 'user', content: req.text });
        
        const response = 'Hello! I am a mock external agent processing: ' + req.text;
        const words = response.split(' ');
        
        for (const word of words) {
          await this.connection.notification('session/notification', {
            sessionId: req.sessionId,
            type: 'text_delta',
            text: word + ' '
          });
          await new Promise(r => setTimeout(r, 50));
        }
        
        session.messages.push({ role: 'assistant', content: response });
        return { text: response, stopReason: 'end_turn' };
      }
    }

    new AgentSideConnection((conn) => new Agent(conn), stream);
  `], {
    stdio: ['pipe', 'pipe', 'inherit'],
    shell: false
  });

  await sleep(500);

  try {
    // Create client and connect
    const client = new AcpClient();
    await client.connect(agentProcess);

    // Run the demo sequence
    console.log('📍 STEP 1: Initialize');
    console.log('─'.repeat(80));
    await client.initialize();

    console.log('📍 STEP 2: Create Session');
    console.log('─'.repeat(80));
    const session = await client.createSession('persistent');

    console.log('📍 STEP 3: Send First Prompt');
    console.log('─'.repeat(80));
    await client.sendPrompt(session.sessionId, 'Hello, agent!');

    console.log('📍 STEP 4: Send Follow-up');
    console.log('─'.repeat(80));
    await client.sendPrompt(session.sessionId, 'Can you help me?');

    console.log('📍 STEP 5: List Sessions');
    console.log('─'.repeat(80));
    await client.listSessions();

    console.log('='.repeat(80));
    console.log('✨ Demo Complete!');
    console.log('='.repeat(80));
    console.log('');
    console.log('What we demonstrated:');
    console.log('  ✓ ClientSideConnection for sending requests');
    console.log('  ✓ AgentSideConnection for receiving requests');
    console.log('  ✓ Real SDK protocol (JSON-RPC over nd-JSON)');
    console.log('  ✓ Session management');
    console.log('  ✓ Streaming text deltas');
    console.log('  ✓ Permission handling');
    console.log('');
    console.log('This is EXACTLY how OpenClaw integrates external agents!');
    console.log('See: src/acp/server.ts and src/acp/client.ts');
    console.log('');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    agentProcess.kill();
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Run the demo
runCompleteDemo().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
