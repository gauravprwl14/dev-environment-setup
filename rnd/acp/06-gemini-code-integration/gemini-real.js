/**
 * Real Gemini CLI Integration with @agentclientprotocol/sdk
 *
 * This demonstrates how to spawn and communicate with the Gemini CLI
 * using the real ACP SDK, just like OpenClaw does.
 *
 * Prerequisites:
 * 1. Install @agentclientprotocol/sdk: npm install (done)
 * 2. Install the Gemini CLI globally: npm install -g @google/gemini-cli
 *    OR use npx: npx @google/gemini-cli (handled automatically if not installed)
 * 3. Set GEMINI_API_KEY environment variable
 *
 * How OpenClaw uses Gemini (from extensions/acpx/src/runtime-internals/mcp-agent-command.ts):
 *   gemini: "gemini"
 *
 * The Gemini CLI speaks ACP natively — no wrapper needed, unlike Claude.
 */

import { spawn, execSync } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { writeFileSync } from 'node:fs';
import { ClientSideConnection, ndJsonStream, PROTOCOL_VERSION } from '@agentclientprotocol/sdk';
import * as readline from 'node:readline';

// ============================================================================
// Gemini Client — Real ACP Integration
// ============================================================================

class GeminiClient {
  constructor() {
    this.client = null;
    this.process = null;
    this.sessionId = null;
    this.collectedText = '';  // Accumulates full response text across chunks
  }

  /**
   * Initialize connection to the Gemini CLI
   */
  async connect(options = {}) {
    const {
      cwd = process.cwd(),
    } = options;

    console.log('🚀 Connecting to Gemini CLI...\n');

    // 1. Resolve the Gemini command
    //    OpenClaw uses: "gemini" (expects global install)
    //    We also support npx fallback for convenience.
    let command, args;
    try {
      execSync('gemini --version', { stdio: 'pipe' });
      command = 'gemini';
      args = ['--acp'];  // Required: starts Gemini in ACP mode (JSON-RPC over stdio)
    } catch {
      // Not installed globally — fall back to npx
      command = 'npx';
      args = ['-y', '@google/gemini-cli', '--acp'];
    }

    const displayCmd = command === 'gemini'
      ? 'gemini --acp (global install)'
      : 'npx -y @google/gemini-cli --acp (auto-download)';

    console.log(`📝 Spawning: ${displayCmd}`);

    // 2. Spawn the Gemini CLI in ACP mode
    //    Without --acp the CLI starts an interactive terminal UI and hangs.
    this.process = spawn(command, args, {
      stdio: ['pipe', 'pipe', 'inherit'],  // stdin, stdout, stderr
      cwd,
      env: {
        ...process.env,
        // Google Gemini API key for authentication
        GEMINI_API_KEY: process.env.GEMINI_API_KEY,
        GOOGLE_API_KEY: process.env.GOOGLE_API_KEY,
      }
    });

    if (!this.process.stdin || !this.process.stdout) {
      throw new Error('Failed to create stdio pipes for Gemini CLI');
    }

    // 3. Create ACP streams (same pattern as every other ACP agent)
    const input = Writable.toWeb(this.process.stdin);
    const output = Readable.toWeb(this.process.stdout);
    const stream = ndJsonStream(input, output);

    console.log('✅ Streams created\n');

    // 4. Create ClientSideConnection with handlers
    this.client = new ClientSideConnection(
      () => ({
        // Handle session updates from Gemini
        sessionUpdate: async (notification) => {
          this.handleSessionUpdate(notification);
        },

        // Handle permission requests from Gemini
        requestPermission: async (params) => {
          return this.handlePermissionRequest(params);
        }
      }),
      stream
    );

    console.log('✅ Client connection created\n');

    // 5. Initialize the ACP connection
    console.log('🔌 Initializing ACP protocol...');

    await this.client.initialize({
      protocolVersion: PROTOCOL_VERSION,
      clientCapabilities: {
        fs: { readTextFile: true, writeTextFile: true },
        terminal: true,
      },
      clientInfo: {
        name: 'openclaw-gemini-demo',
        version: '1.0.0'
      }
    });

    console.log(`✅ Initialized with protocol version: ${PROTOCOL_VERSION}\n`);

    // 6. Create a new session
    console.log('📝 Creating new Gemini session...');

    const session = await this.client.newSession({
      cwd,
      mcpServers: []  // Model Context Protocol servers (optional)
    });

    this.sessionId = session.sessionId;

    console.log(`✅ Session created: ${this.sessionId}\n`);
    console.log('━'.repeat(80));
    console.log('🎉 Ready to interact with Gemini!');
    console.log('━'.repeat(80));
    console.log('');
  }

  /**
   * Send a prompt to Gemini, returns { response, collectedText }
   */
  async sendPrompt(text) {
    if (!this.client || !this.sessionId) {
      throw new Error('Not connected. Call connect() first.');
    }

    console.log(`\n💬 You: ${text}\n`);
    console.log('🤔 Gemini is thinking...\n');

    this.collectedText = '';  // Reset for this prompt

    try {
      const response = await this.client.prompt({
        sessionId: this.sessionId,
        prompt: [{ type: 'text', text }]
      });

      console.log('\n✅ Response received');
      console.log(`   Stop reason: ${response.stopReason || 'unknown'}\n`);

      return { response, collectedText: this.collectedText };
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
        // Stream Gemini's response as it types and accumulate for post-processing
        if (update.content?.type === 'text') {
          process.stdout.write(update.content.text);
          this.collectedText += update.content.text;
        }
        break;

      case 'agent_thought_chunk':
        // Gemini's internal reasoning (thinking mode)
        if (update.content?.type === 'text') {
          process.stderr.write(`[thinking] ${update.content.text}\n`);
        }
        break;

      case 'tool_call':
        // Gemini is using a tool (read_file, run_command, etc.)
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
        // Gemini's plan for solving the task
        if (update.content?.type === 'text') {
          console.log(`\n📋 Plan: ${update.content.text}\n`);
        }
        break;

      default:
        if (update.sessionUpdate) {
          console.log(`ℹ️  Update: ${update.sessionUpdate}`);
        }
    }
  }

  /**
   * Handle permission requests from Gemini
   */
  async handlePermissionRequest(params) {
    const toolTitle = params.toolCall?.title || 'unknown tool';
    const options = params.options || [];

    console.log(`\n🔐 PERMISSION REQUEST`);
    console.log(`   Tool: ${toolTitle}`);
    console.log(`   Options: ${options.length} available\n`);

    // Auto-approve read operations
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
    console.log('\n👋 Closing connection to Gemini CLI...');

    if (this.process) {
      this.process.kill();
    }

    console.log('✅ Connection closed\n');
  }
}

// ============================================================================
// Demo: Interactive Session with Gemini
// ============================================================================

async function main() {
  console.log('');
  console.log('='.repeat(80));
  console.log('🎯 Gemini CLI Integration with Real ACP SDK');
  console.log('='.repeat(80));
  console.log('');
  console.log('This example demonstrates:');
  console.log('  ✓ Spawning Gemini CLI as a child process (ACP native)');
  console.log('  ✓ Using @agentclientprotocol/sdk for communication');
  console.log('  ✓ Handling streaming responses in real-time');
  console.log('  ✓ Managing tool permission requests');
  console.log('  ✓ Interactive conversation with Gemini');
  console.log('');
  console.log('Prerequisites:');
  console.log('  1. @agentclientprotocol/sdk installed (✓)');
  console.log('  2. Gemini CLI: npm install -g @google/gemini-cli  (or npx auto-download)');
  console.log('  3. Set GEMINI_API_KEY environment variable');
  console.log('');

  const client = new GeminiClient();

  try {
    await client.connect({ cwd: process.cwd() });

    // Generate an SVG diagram explaining the ACP protocol
    console.log('\n📍 EXAMPLE: Generate ACP Architecture SVG');
    console.log('━'.repeat(80));

    const { collectedText } = await client.sendPrompt(
      'Generate a single self-contained SVG image (no external dependencies, inline styles only) ' +
      'that visually explains how the Agent Client Protocol (ACP) works for beginners building AI agents. ' +
      'The diagram should show: (1) the Client app on the left, (2) the ACP SDK in the middle, ' +
      '(3) the AI Agent process on the right, and (4) the JSON-RPC message flow between them ' +
      '(initialize → newSession → prompt → sessionUpdate notifications → response). ' +
      'Use clear labels, arrows, and a clean color scheme. ' +
      'Reply with ONLY the raw SVG markup, starting with <svg and ending with </svg>. No markdown, no explanation.'
    );

    // Extract SVG from the response (strip any markdown fences if present)
    const svgMatch = collectedText.match(/<svg[\s\S]*<\/svg>/i);
    if (svgMatch) {
      const svgContent = svgMatch[0];
      const outPath = new URL('./acp-diagram.svg', import.meta.url).pathname;
      writeFileSync(outPath, svgContent, 'utf8');
      console.log(`\n💾 SVG saved to: acp-diagram.svg`);
      console.log('   Open it in your browser to view the diagram.');
    } else {
      console.log('\n⚠️  No SVG block found in response. Raw output saved to acp-diagram.txt');
      const outPath = new URL('./acp-diagram.txt', import.meta.url).pathname;
      writeFileSync(outPath, collectedText, 'utf8');
    }

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
    console.log('This is exactly how OpenClaw integrates with Gemini!');
    console.log('See: extensions/acpx/src/runtime-internals/mcp-agent-command.ts');
    console.log('');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('\nTroubleshooting:');
    console.error('  • Install Gemini CLI: npm install -g @google/gemini-cli');
    console.error('  • Set GEMINI_API_KEY: export GEMINI_API_KEY="your-key"');
    console.error('  • Get API key from: https://aistudio.google.com/apikey');
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

export { GeminiClient };
