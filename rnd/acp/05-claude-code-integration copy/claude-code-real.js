/**
 * Real Claude Code Integration with @agentclientprotocol/sdk
 * 
 * This demonstrates how to spawn and communicate with Claude Code CLI
 * using the real ACP SDK, just like OpenClaw does.
 * 
 * Prerequisites:
 * 1. Install @agentclientprotocol/sdk: npm install (done)
 * 2. The ACP wrapper downloads automatically via npx
 * 3. Set ANTHROPIC_API_KEY if needed
 * 
 * IMPORTANT: Uses @agentclientprotocol/claude-agent-acp (ACP wrapper),
 * NOT the standard 'claude' CLI!
 */

import { spawn } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { ClientSideConnection, ndJsonStream, PROTOCOL_VERSION } from '@agentclientprotocol/sdk';
import * as readline from 'node:readline';

// ============================================================================
// Claude Code Client - Real Integration
// ============================================================================

class ClaudeCodeClient {
  constructor() {
    this.client = null;
    this.process = null;
    this.sessionId = null;
  }

  /**
   * Initialize connection to Claude Code CLI
   */
  async connect(options = {}) {
    const {
      cwd = process.cwd(),
      verbose = true
    } = options;

    console.log('🚀 Connecting to Claude Code CLI...\n');

    // 1. Spawn the ACP-compatible Claude wrapper
    // IMPORTANT: Use @agentclientprotocol/claude-agent-acp, NOT standard 'claude' CLI!
    console.log('📝 Spawning: npx -y @agentclientprotocol/claude-agent-acp');
    
    this.process = spawn('npx', ['-y', '@agentclientprotocol/claude-agent-acp'], {
      stdio: ['pipe', 'pipe', 'inherit'],  // stdin, stdout, stderr
      cwd,
      env: {
        ...process.env,
        // Anthropic API key for authentication
        ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
      }
    });

    if (!this.process.stdin || !this.process.stdout) {
      throw new Error('Failed to create stdio pipes for Claude Code');
    }

    // 2. Create ACP streams
    const input = Writable.toWeb(this.process.stdin);
    const output = Readable.toWeb(this.process.stdout);
    const stream = ndJsonStream(input, output);

    console.log('✅ Streams created\n');

    // 3. Create ClientSideConnection with handlers
    this.client = new ClientSideConnection(
      () => ({
        // Handle session updates from Claude Code
        sessionUpdate: async (notification) => {
          this.handleSessionUpdate(notification);
        },

        // Handle permission requests from Claude Code
        requestPermission: async (params) => {
          return this.handlePermissionRequest(params);
        }
      }),
      stream
    );

    console.log('✅ Client connection created\n');

    // 4. Initialize the ACP connection
    console.log('🔌 Initializing ACP protocol...');
    
    await this.client.initialize({
      protocolVersion: PROTOCOL_VERSION,
      clientCapabilities: {
        fs: { readTextFile: true, writeTextFile: true },
        terminal: true,
      },
      clientInfo: {
        name: 'openclaw-claude-demo',
        version: '1.0.0'
      }
    });

    console.log(`✅ Initialized with protocol version: ${PROTOCOL_VERSION}\n`);

    // 5. Create a new session
    console.log('📝 Creating new Claude Code session...');
    
    const session = await this.client.newSession({
      cwd,
      mcpServers: []  // Model Context Protocol servers (optional)
    });

    this.sessionId = session.sessionId;
    
    console.log(`✅ Session created: ${this.sessionId}\n`);
    console.log('━'.repeat(80));
    console.log('🎉 Ready to interact with Claude Code!');
    console.log('━'.repeat(80));
    console.log('');
  }

  /**
   * Send a prompt to Claude Code
   */
  async sendPrompt(text) {
    if (!this.client || !this.sessionId) {
      throw new Error('Not connected. Call connect() first.');
    }

    console.log(`\n💬 You: ${text}\n`);
    console.log('🤔 Claude is thinking...\n');

    try {
      // Correct ACP format: prompt is an array of ContentBlock objects
      const response = await this.client.prompt({
        sessionId: this.sessionId,
        prompt: [
          {
            type: 'text',
            text
          }
        ]
      });

      console.log('\n✅ Response received');
      console.log(`   Stop reason: ${response.stopReason || 'unknown'}\n`);

      return response;
    } catch (error) {
      console.error('\n❌ Error sending prompt:', error.message);
      throw error;
    }
  }

  /**
   * Handle session updates (streaming responses)
   */
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
        }
        break;

      case 'agent_thought_chunk':
        // Claude's internal reasoning (if enabled)
        if (update.content?.type === 'text') {
          process.stderr.write(`[thinking] ${update.content.text}\n`);
        }
        break;

      case 'tool_call':
        // Claude is using a tool (read_file, run_command, etc.)
        console.log(`\n🔧 Tool: ${update.title || 'unnamed'}`);
        if (update.status) {
          console.log(`   Status: ${update.status}`);
        }
        break;

      case 'tool_call_update':
        // Tool execution progress
        if (update.status === 'success') {
          console.log(`✅ Tool completed: ${update.toolCallId}`);
        } else if (update.status === 'error') {
          console.log(`❌ Tool failed: ${update.toolCallId}`);
        }
        break;

      case 'plan':
        // Claude's plan for solving the task
        if (update.content?.type === 'text') {
          console.log(`\n📋 Plan: ${update.content.text}\n`);
        }
        break;

      default:
        // Other update types
        if (update.sessionUpdate) {
          console.log(`ℹ️  Update: ${update.sessionUpdate}`);
        }
    }
  }

  /**
   * Handle permission requests from Claude Code
   */
  async handlePermissionRequest(params) {
    const toolTitle = params.toolCall?.title || 'unknown tool';
    const options = params.options || [];

    console.log(`\n🔐 PERMISSION REQUEST`);
    console.log(`   Tool: ${toolTitle}`);
    console.log(`   Options: ${options.length} available\n`);

    // For this demo, auto-approve read operations, prompt for others
    const isRead = toolTitle.toLowerCase().includes('read');
    
    if (isRead) {
      console.log('✅ Auto-approved (read operation)\n');
      const allowOption = options.find(opt => 
        opt.kind === 'allow_once' || opt.kind === 'allow_always'
      );
      
      if (allowOption) {
        return {
          outcome: {
            outcome: 'selected',
            optionId: allowOption.optionId
          }
        };
      }
    }

    // For other operations, ask the user
    return new Promise((resolve) => {
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });

      rl.question(`Allow "${toolTitle}"? (y/N) `, (answer) => {
        rl.close();
        
        const approved = answer.trim().toLowerCase() === 'y';
        console.log(approved ? '✅ Approved\n' : '❌ Denied\n');

        if (approved) {
          const allowOption = options.find(opt => 
            opt.kind === 'allow_once' || opt.kind === 'allow_always'
          );
          if (allowOption) {
            resolve({
              outcome: {
                outcome: 'selected',
                optionId: allowOption.optionId
              }
            });
            return;
          }
        }

        // Deny or cancel
        const rejectOption = options.find(opt => 
          opt.kind === 'reject_once' || opt.kind === 'reject_always'
        );
        
        if (rejectOption) {
          resolve({
            outcome: {
              outcome: 'selected',
              optionId: rejectOption.optionId
            }
          });
        } else {
          resolve({
            outcome: {
              outcome: 'cancelled'
            }
          });
        }
      });
    });
  }

  /**
   * Close the connection
   */
  async close() {
    console.log('\n👋 Closing connection to Claude Code...');
    
    if (this.process) {
      this.process.kill();
    }
    
    console.log('✅ Connection closed\n');
  }
}

// ============================================================================
// Demo: Interactive Session with Claude Code
// ============================================================================

async function main() {
  console.log('');
  console.log('='.repeat(80));
  console.log('🎯 Claude Code Integration with Real ACP SDK');
  console.log('='.repeat(80));
  console.log('');
  console.log('This example demonstrates:');
  console.log('  ✓ Spawning Claude ACP wrapper as a child process');
  console.log('  ✓ Using @agentclientprotocol/sdk for communication');
  console.log('  ✓ Handling streaming responses in real-time');
  console.log('  ✓ Managing tool permission requests');
  console.log('  ✓ Interactive conversation with Claude');
  console.log('');
  console.log('Prerequisites:');
  console.log('  1. @agentclientprotocol/sdk installed (✓)');
  console.log('  2. ACP wrapper downloads automatically via npx (✓)');
  console.log('  3. Set ANTHROPIC_API_KEY environment variable if needed');
  console.log('');

  const client = new ClaudeCodeClient();

  try {
    // Connect to Claude Code
    await client.connect({
      cwd: process.cwd(),
      verbose: true
    });

    // // Example 1: Simple question
    // console.log('\n📍 EXAMPLE 1: Simple Question');
    // console.log('━'.repeat(80));
    // await client.sendPrompt('What is the capital of France?');

    // await sleep(2000);

    // // Example 2: Code-related task
    // console.log('\n📍 EXAMPLE 2: Code Analysis');
    // console.log('━'.repeat(80));
    // await client.sendPrompt('Can you tell me what files are in the current directory?');

    // await sleep(2000);

    // Example 3: Code generation
    console.log('\n📍 EXAMPLE 3: Code Generation');
    console.log('━'.repeat(80));
    await client.sendPrompt('Can you tell which claude code account we are using?');

    await sleep(2000);

    // Close connection
    await client.close();

    console.log('');
    console.log('='.repeat(80));
    console.log('✨ Demo Complete!');
    console.log('='.repeat(80));
    console.log('');
    console.log('Key SDK Features Demonstrated:');
    console.log('  ✓ ClientSideConnection - Client-side ACP connection');
    console.log('  ✓ ndJsonStream - Protocol stream handler');
    console.log('  ✓ initialize() - Protocol handshake');
    console.log('  ✓ newSession() - Session creation');
    console.log('  ✓ prompt() - Sending messages');
    console.log('  ✓ sessionUpdate - Streaming responses');
    console.log('  ✓ requestPermission - Tool approval workflow');
    console.log('');
    console.log('This is exactly how OpenClaw integrates with Claude Code!');
    console.log('See: src/acp/client.ts in the OpenClaw repository');
    console.log('');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('\nTroubleshooting:');
    console.error('  • Make sure npx is available: npm --version');
    console.error('  • Set ANTHROPIC_API_KEY: export ANTHROPIC_API_KEY="sk-ant-..."');
    console.error('  • Get API key from: https://console.anthropic.com/');
    console.error('  • The ACP wrapper downloads automatically via npx');
    console.error('');
    process.exit(1);
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Run the demo
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { ClaudeCodeClient };
