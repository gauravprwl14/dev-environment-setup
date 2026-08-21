/**
 * Interactive Chat with Claude via ACP
 * 
 * Continuous conversation interface just like Claude Code and OpenClaw.
 * Type your messages and get streaming responses in real-time.
 * 
 * Commands:
 *   /exit or /quit - Exit the chat
 *   /help - Show available commands
 *   /clear - Clear the screen
 * 
 * Prerequisites:
 *   1. npm install (installs @agentclientprotocol/sdk)
 *   2. Set ANTHROPIC_API_KEY if needed (wrapper may handle auth automatically)
 */

import { spawn } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { ClientSideConnection, ndJsonStream, PROTOCOL_VERSION } from '@agentclientprotocol/sdk';
import * as readline from 'node:readline';

// ============================================================================
// Interactive Chat Client
// ============================================================================

class InteractiveChatClient {
  constructor() {
    this.client = null;
    this.process = null;
    this.sessionId = null;
    this.isResponding = false;
    this.currentResponse = '';
  }

  /**
   * Initialize connection to Claude
   */
  async connect() {
    // Spawn the ACP-compatible Claude wrapper
    this.process = spawn('npx', ['-y', '@agentclientprotocol/claude-agent-acp'], {
      stdio: ['pipe', 'pipe', 'pipe'],  // Capture stderr too
      env: {
        ...process.env,
        ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
      }
    });

    if (!this.process.stdin || !this.process.stdout) {
      throw new Error('Failed to create stdio pipes');
    }

    // Suppress stderr (wrapper download messages, etc.)
    this.process.stderr.on('data', () => {});

    // Create ACP streams
    const input = Writable.toWeb(this.process.stdin);
    const output = Readable.toWeb(this.process.stdout);
    const stream = ndJsonStream(input, output);

    // Create ClientSideConnection with handlers
    this.client = new ClientSideConnection(
      () => ({
        sessionUpdate: async (notification) => {
          this.handleSessionUpdate(notification);
        },
        requestPermission: async (params) => {
          return this.handlePermissionRequest(params);
        }
      }),
      stream
    );

    // Initialize the ACP connection
    await this.client.initialize({
      protocolVersion: PROTOCOL_VERSION,
      clientCapabilities: {
        fs: { readTextFile: true, writeTextFile: true },
        terminal: true,
      },
      clientInfo: {
        name: 'interactive-chat',
        version: '1.0.0'
      }
    });

    // Create a new session
    const session = await this.client.newSession({
      cwd: process.cwd(),
      mcpServers: []
    });

    this.sessionId = session.sessionId;
  }

  /**
   * Send a message to Claude
   */
  async sendMessage(text) {
    if (!this.client || !this.sessionId) {
      throw new Error('Not connected');
    }

    this.isResponding = true;
    this.currentResponse = '';

    try {
      const response = await this.client.prompt({
        sessionId: this.sessionId,
        prompt: [{ type: 'text', text }]
      });

      this.isResponding = false;
      return response;
    } catch (error) {
      this.isResponding = false;
      throw error;
    }
  }

  /**
   * Handle streaming responses from Claude
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
          this.currentResponse += update.content.text;
        }
        break;

      case 'tool_call':
        // Claude is using a tool
        const toolName = update.title || 'unknown';
        console.log(`\n\n🔧 Using tool: ${toolName}`);
        break;

      case 'tool_call_update':
        // Tool execution progress
        if (update.status === 'success') {
          console.log(`✅ Tool completed`);
        } else if (update.status === 'error') {
          console.log(`❌ Tool failed`);
        }
        break;

      case 'plan':
        // Claude's plan (if reasoning is enabled)
        if (update.content?.type === 'text') {
          console.log(`\n💭 Planning: ${update.content.text}`);
        }
        break;
    }
  }

  /**
   * Handle permission requests for tools
   */
  async handlePermissionRequest(params) {
    const toolTitle = params.toolCall?.title || 'unknown tool';
    const options = params.options || [];

    // Auto-approve safe read operations
    const safeTools = ['read_file', 'list_directory', 'search_files'];
    const isSafe = safeTools.some(tool => toolTitle.toLowerCase().includes(tool));
    
    if (isSafe) {
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

    // For potentially dangerous operations, ask the user
    console.log(`\n\n🔐 Permission requested: ${toolTitle}`);
    
    return new Promise((resolve) => {
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });

      rl.question(`Allow? (y/N): `, (answer) => {
        rl.close();
        
        const approved = answer.trim().toLowerCase() === 'y';

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

        // Deny
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
  close() {
    if (this.process) {
      this.process.kill();
    }
  }
}

// ============================================================================
// Interactive Chat Loop
// ============================================================================

async function startInteractiveChat() {
  console.clear();
  console.log('╔════════════════════════════════════════════════════════════════════════════╗');
  console.log('║                   Interactive Chat with Claude via ACP                     ║');
  console.log('╚════════════════════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('Commands: /exit, /quit, /help, /clear');
  console.log('');

  const client = new InteractiveChatClient();

  try {
    // Connect to Claude
    process.stdout.write('🔌 Connecting to Claude');
    const connectInterval = setInterval(() => process.stdout.write('.'), 500);
    
    await client.connect();
    
    clearInterval(connectInterval);
    console.log(' ✅\n');
    console.log('━'.repeat(80));
    console.log('💬 Ready to chat! Type your message and press Enter.');
    console.log('━'.repeat(80));
    console.log('');

    // Create readline interface for user input
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      prompt: '\n\x1b[36mYou:\x1b[0m '  // Cyan prompt
    });

    // Show initial prompt
    rl.prompt();

    // Handle user input
    rl.on('line', async (input) => {
      const message = input.trim();

      // Handle commands
      if (message.startsWith('/')) {
        const command = message.toLowerCase();

        if (command === '/exit' || command === '/quit') {
          console.log('\n👋 Goodbye!\n');
          client.close();
          rl.close();
          process.exit(0);
        } else if (command === '/help') {
          console.log('\nAvailable commands:');
          console.log('  /exit, /quit  - Exit the chat');
          console.log('  /help         - Show this help message');
          console.log('  /clear        - Clear the screen');
          console.log('');
          rl.prompt();
          return;
        } else if (command === '/clear') {
          console.clear();
          console.log('Chat cleared. Continue the conversation...\n');
          rl.prompt();
          return;
        } else {
          console.log(`\n❌ Unknown command: ${command}`);
          console.log('Type /help for available commands\n');
          rl.prompt();
          return;
        }
      }

      // Skip empty messages
      if (!message) {
        rl.prompt();
        return;
      }

      // Send message to Claude
      try {
        console.log('\n\x1b[35mClaude:\x1b[0m ');  // Magenta label
        
        await client.sendMessage(message);
        
        console.log('\n');
        rl.prompt();
      } catch (error) {
        console.error(`\n❌ Error: ${error.message}\n`);
        rl.prompt();
      }
    });

    // Handle Ctrl+C gracefully
    rl.on('SIGINT', () => {
      console.log('\n\n👋 Goodbye!\n');
      client.close();
      process.exit(0);
    });

    // Handle exit
    rl.on('close', () => {
      client.close();
      process.exit(0);
    });

  } catch (error) {
    console.error(`\n❌ Connection failed: ${error.message}\n`);
    console.error('Troubleshooting:');
    console.error('  • Make sure npx is available: npm --version');
    console.error('  • Set ANTHROPIC_API_KEY: export ANTHROPIC_API_KEY="sk-ant-..."');
    console.error('  • Get API key from: https://console.anthropic.com/');
    console.error('  • The ACP wrapper downloads automatically via npx');
    console.error('');
    process.exit(1);
  }
}

// Start the interactive chat
startInteractiveChat().catch((error) => {
  console.error('\n❌ Fatal error:', error.message);
  process.exit(1);
});
