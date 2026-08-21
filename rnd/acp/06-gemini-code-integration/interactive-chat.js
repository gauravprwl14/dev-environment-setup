/**
 * Interactive Chat with Gemini via ACP
 *
 * Continuous conversation interface — just like Gemini CLI and OpenClaw.
 * Type your messages and get streaming responses in real-time.
 *
 * Commands:
 *   /exit or /quit - Exit the chat
 *   /help - Show available commands
 *   /clear - Clear the screen
 *   /debug - Toggle debug mode (shows all ACP update types)
 *
 * Prerequisites:
 *   1. npm install (installs @agentclientprotocol/sdk)
 *   2. Install Gemini CLI: npm install -g @google/gemini-cli
 *      OR let npx auto-download it on first run
 *   3. Set GEMINI_API_KEY environment variable
 */

import { spawn, execSync } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { ClientSideConnection, ndJsonStream, PROTOCOL_VERSION } from '@agentclientprotocol/sdk';
import * as readline from 'node:readline';

// ============================================================================
// Interactive Chat Client
// ============================================================================

class GeminiInteractiveChatClient {
  constructor() {
    this.client = null;
    this.process = null;
    this.sessionId = null;
    this.debug = false;          // Toggle with /debug command
    this.labelPrinted = false;   // Ensure "Gemini:" label only prints once per turn
    this.hasContent = false;     // Track if any content was received this turn

    // Single readline interface shared across the whole session.
    // Permission requests reuse this same rl instead of creating a new one,
    // which avoids stdin conflicts.
    this.rl = null;
  }

  /**
   * Initialize connection to Gemini
   */
  async connect() {
    let command, args;
    try {
      execSync('gemini --version', { stdio: 'pipe' });
      command = 'gemini';
      args = ['--acp'];
    } catch {
      command = 'npx';
      args = ['-y', '@google/gemini-cli', '--acp'];
    }

    this.process = spawn(command, args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: {
        ...process.env,
        GEMINI_API_KEY: process.env.GEMINI_API_KEY,
        GOOGLE_API_KEY: process.env.GOOGLE_API_KEY,
      }
    });

    if (!this.process.stdin || !this.process.stdout) {
      throw new Error('Failed to create stdio pipes');
    }

    // Suppress noisy stderr from the CLI (download progress, cache messages, etc.)
    this.process.stderr.on('data', () => {});

    const input = Writable.toWeb(this.process.stdin);
    const output = Readable.toWeb(this.process.stdout);
    const stream = ndJsonStream(input, output);

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

    await this.client.initialize({
      protocolVersion: PROTOCOL_VERSION,
      clientCapabilities: {
        fs: { readTextFile: true, writeTextFile: true },
        terminal: true,
      },
      clientInfo: {
        name: 'gemini-interactive-chat',
        version: '1.0.0'
      }
    });

    const session = await this.client.newSession({
      cwd: process.cwd(),
      mcpServers: []
    });

    this.sessionId = session.sessionId;
  }

  /**
   * Send a message to Gemini
   */
  async sendMessage(text) {
    if (!this.client || !this.sessionId) {
      throw new Error('Not connected');
    }

    // Reset per-turn state
    this.labelPrinted = false;
    this.hasContent = false;

    try {
      await this.client.prompt({
        sessionId: this.sessionId,
        prompt: [{ type: 'text', text }]
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Print the "Gemini:" label exactly once per turn, before first content.
   */
  ensureLabel() {
    if (!this.labelPrinted) {
      this.labelPrinted = true;
      process.stdout.write('\n\x1b[35mGemini:\x1b[0m ');
    }
  }

  /**
   * Handle all streaming updates from Gemini.
   *
   * Debug mode (/debug) prints every raw update so you can see exactly
   * what the Gemini CLI sends — useful for diagnosing missing responses.
   */
  handleSessionUpdate(notification) {
    const update = notification.update;

    if (this.debug) {
      process.stderr.write(`\n[DEBUG] update type: ${update.sessionUpdate ?? '(no sessionUpdate key)'}\n`);
      process.stderr.write(`[DEBUG] keys: ${Object.keys(update).join(', ')}\n`);
      if (update.content) {
        process.stderr.write(`[DEBUG] content: ${JSON.stringify(update.content)}\n`);
      }
    }

    if (!('sessionUpdate' in update)) {
      // Some notifications carry raw content without a sessionUpdate discriminator
      if (update.content?.type === 'text' && update.content.text) {
        this.ensureLabel();
        process.stdout.write(update.content.text);
        this.hasContent = true;
      }
      return;
    }

    switch (update.sessionUpdate) {
      case 'agent_message_chunk':
        if (update.content?.type === 'text' && update.content.text) {
          this.ensureLabel();
          process.stdout.write(update.content.text);
          this.hasContent = true;
        }
        break;

      case 'agent_thought_chunk':
        // Gemini's internal thinking — show dimmed if debug is on
        if (this.debug && update.content?.type === 'text') {
          process.stderr.write(`\x1b[2m[thinking] ${update.content.text}\x1b[0m`);
        }
        break;

      case 'tool_call':
        process.stdout.write(`\n\n🔧 Using tool: ${update.title || 'unknown'}\n`);
        break;

      case 'tool_call_update': {
        // Gemini sometimes delivers the final answer inside a tool_call_update
        // (e.g. after delegating to a sub-agent like cli_help).
        if (update.content?.type === 'text' && update.content.text) {
          this.ensureLabel();
          process.stdout.write(update.content.text);
          this.hasContent = true;
        } else if (update.status === 'success') {
          process.stdout.write('✅ Tool completed\n');
        } else if (update.status === 'error') {
          process.stdout.write('❌ Tool failed\n');
        }
        break;
      }

      case 'plan':
        if (update.content?.type === 'text') {
          process.stdout.write(`\n💭 ${update.content.text}\n`);
        }
        break;

      default:
        // Catch-all: if any update type carries text content, display it.
        // This ensures we never silently drop Gemini's output regardless of
        // which update type the CLI uses in future versions.
        if (update.content?.type === 'text' && update.content.text) {
          this.ensureLabel();
          process.stdout.write(update.content.text);
          this.hasContent = true;
        } else if (this.debug) {
          process.stderr.write(`[DEBUG] unhandled update: ${update.sessionUpdate}\n`);
        }
        break;
    }
  }

  /**
   * Handle permission requests using the shared readline interface.
   *
   * Creating a second readline on stdin while the main rl is active steals
   * input and breaks both interfaces. We pause the main rl instead and
   * ask the question directly on stdout/stdin via a one-shot question.
   */
  async handlePermissionRequest(params) {
    const toolTitle = params.toolCall?.title || 'unknown tool';
    const options = params.options || [];

    const safeTools = ['read_file', 'list_directory', 'search_files'];
    const isSafe = safeTools.some(tool => toolTitle.toLowerCase().includes(tool));

    if (isSafe) {
      const allowOption = options.find(opt =>
        opt.kind === 'allow_once' || opt.kind === 'allow_always'
      );
      if (allowOption) {
        return { outcome: { outcome: 'selected', optionId: allowOption.optionId } };
      }
    }

    process.stdout.write(`\n\n🔐 Permission requested: "${toolTitle}"\n`);

    return new Promise((resolve) => {
      // Pause the main readline so it doesn't swallow our question
      if (this.rl) this.rl.pause();

      this.rl.question('Allow? (y/N): ', (answer) => {
        if (this.rl) this.rl.resume();

        const approved = answer.trim().toLowerCase() === 'y';

        if (approved) {
          const allowOption = options.find(opt =>
            opt.kind === 'allow_once' || opt.kind === 'allow_always'
          );
          if (allowOption) {
            resolve({ outcome: { outcome: 'selected', optionId: allowOption.optionId } });
            return;
          }
        }

        const rejectOption = options.find(opt =>
          opt.kind === 'reject_once' || opt.kind === 'reject_always'
        );
        if (rejectOption) {
          resolve({ outcome: { outcome: 'selected', optionId: rejectOption.optionId } });
        } else {
          resolve({ outcome: { outcome: 'cancelled' } });
        }
      });
    });
  }

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
  console.log('║                  Interactive Chat with Gemini via ACP                      ║');
  console.log('╚════════════════════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('Commands: /exit, /quit, /help, /clear, /debug');
  console.log('');

  const client = new GeminiInteractiveChatClient();

  try {
    process.stdout.write('🔌 Connecting to Gemini');
    const connectInterval = setInterval(() => process.stdout.write('.'), 500);

    await client.connect();

    clearInterval(connectInterval);
    console.log(' ✅\n');
    console.log('━'.repeat(80));
    console.log('💬 Ready to chat! Type your message and press Enter.');
    console.log('━'.repeat(80));
    console.log('');

    // Create the single shared readline interface
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      prompt: '\n\x1b[36mYou:\x1b[0m '
    });

    // Share it with the client so permission requests can reuse it
    client.rl = rl;

    rl.prompt();

    rl.on('line', async (input) => {
      const message = input.trim();

      // Handle slash commands
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
          console.log('  /debug        - Toggle debug mode (shows all ACP update types)');
          console.log('');
          rl.prompt();

        } else if (command === '/clear') {
          console.clear();
          console.log('Chat cleared. Continue the conversation...\n');
          rl.prompt();

        } else if (command === '/debug') {
          client.debug = !client.debug;
          console.log(`\n🔍 Debug mode: ${client.debug ? 'ON' : 'OFF'}\n`);
          rl.prompt();

        } else {
          console.log(`\n❌ Unknown command: ${command}`);
          console.log('Type /help for available commands\n');
          rl.prompt();
        }
        return;
      }

      if (!message) {
        rl.prompt();
        return;
      }

      // Pause readline while Gemini responds (prevents buffering typed input)
      rl.pause();

      try {
        await client.sendMessage(message);

        // If Gemini produced no streamed text at all, say so
        if (!client.hasContent) {
          console.log('\n\x1b[33m(no text response — Gemini may have used a tool; try /debug for details)\x1b[0m');
        }

        console.log('\n');
      } catch (error) {
        console.error(`\n❌ Error: ${error.message}\n`);
      }

      rl.resume();
      rl.prompt();
    });

    rl.on('SIGINT', () => {
      console.log('\n\n👋 Goodbye!\n');
      client.close();
      process.exit(0);
    });

    rl.on('close', () => {
      client.close();
      process.exit(0);
    });

  } catch (error) {
    console.error(`\n❌ Connection failed: ${error.message}\n`);
    console.error('Troubleshooting:');
    console.error('  • Install Gemini CLI: npm install -g @google/gemini-cli');
    console.error('  • Set GEMINI_API_KEY: export GEMINI_API_KEY="your-key"');
    console.error('  • Get API key from: https://aistudio.google.com/apikey');
    console.error('');
    process.exit(1);
  }
}

startInteractiveChat().catch((error) => {
  console.error('\n❌ Fatal error:', error.message);
  process.exit(1);
});
