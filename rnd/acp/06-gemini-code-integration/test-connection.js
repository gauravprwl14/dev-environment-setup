/**
 * Test Connection to Gemini via ACP
 *
 * OpenClaw uses the `gemini` CLI directly (not a wrapper):
 *   gemini: "gemini"   ← from mcp-agent-command.ts
 *
 * The Gemini CLI speaks ACP natively. This test verifies the full
 * spawn → initialize → session → prompt flow works end-to-end.
 */

import { spawn, execSync } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { ClientSideConnection, ndJsonStream, PROTOCOL_VERSION } from '@agentclientprotocol/sdk';

async function testGeminiConnection() {
  console.log('');
  console.log('='.repeat(60));
  console.log('🧪 Testing Gemini ACP Connection');
  console.log('='.repeat(60));
  console.log('');

  console.log('ℹ️  OpenClaw uses the Gemini CLI directly (ACP native):');
  console.log('   • Command: gemini (global install)');
  console.log('   • Fallback: npx @google/gemini-cli');
  console.log('   • No wrapper needed — Gemini speaks ACP natively!');
  console.log('');

  // Test 1: Check available runtime
  console.log('1️⃣  Checking Gemini CLI availability...');

  let command, args;
  try {
    execSync('gemini --version', { stdio: 'pipe' });
    command = 'gemini';
    args = ['--acp'];  // Required: starts Gemini in ACP mode (JSON-RPC over stdio)
    console.log('   ✅ gemini found on PATH (global install)\n');
  } catch {
    command = 'npx';
    args = ['-y', '@google/gemini-cli', '--acp'];
    console.log('   ⚠️  gemini not on PATH — will use npx @google/gemini-cli\n');
  }

  // Test 2: Check GEMINI_API_KEY
  console.log('2️⃣  Checking GEMINI_API_KEY...');

  if (!process.env.GEMINI_API_KEY && !process.env.GOOGLE_API_KEY) {
    console.warn('   ⚠️  Neither GEMINI_API_KEY nor GOOGLE_API_KEY is set.');
    console.warn('       The Gemini CLI may fail to authenticate.\n');
  } else {
    console.log('   ✅ API key found\n');
  }

  // Test 3: Spawn the Gemini CLI
  console.log('3️⃣  Spawning Gemini CLI...');

  let geminiProc = null;
  let client = null;

  try {
    geminiProc = spawn(command, args, {
      stdio: ['pipe', 'pipe', 'inherit'],
      env: {
        ...process.env,
        GEMINI_API_KEY: process.env.GEMINI_API_KEY,
        GOOGLE_API_KEY: process.env.GOOGLE_API_KEY,
      }
    });

    if (!geminiProc.stdin || !geminiProc.stdout) {
      throw new Error('Failed to create stdio pipes');
    }

    const input = Writable.toWeb(geminiProc.stdin);
    const output = Readable.toWeb(geminiProc.stdout);
    const stream = ndJsonStream(input, output);

    client = new ClientSideConnection(
      () => ({
        sessionUpdate: async () => {},
        requestPermission: async () => ({
          outcome: { outcome: 'cancelled' }
        })
      }),
      stream
    );

    console.log('   ✅ Process spawned and streams connected\n');

    // Test 4: Initialize protocol
    console.log('4️⃣  Testing protocol initialization...');

    await client.initialize({
      protocolVersion: PROTOCOL_VERSION,
      clientCapabilities: {
        fs: { readTextFile: true, writeTextFile: true },
        terminal: true,
      },
      clientInfo: {
        name: 'gemini-test',
        version: '1.0.0'
      }
    });

    console.log(`   ✅ Protocol initialized (version: ${PROTOCOL_VERSION})\n`);

    // Test 5: Create a test session
    console.log('5️⃣  Creating test session...');

    const session = await client.newSession({
      cwd: process.cwd(),
      mcpServers: []
    });

    console.log(`   ✅ Session created: ${session.sessionId}\n`);

    // Test 6: Send a simple prompt (with timeout)
    console.log('6️⃣  Testing prompt (with 10s timeout)...');

    const promptPromise = client.prompt({
      sessionId: session.sessionId,
      prompt: [
        {
          type: 'text',
          text: 'Respond with just "Hello from Gemini" and nothing else'
        }
      ]
    });

    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Prompt timeout after 10s')), 10000)
    );

    await Promise.race([promptPromise, timeoutPromise]);

    console.log('   ✅ Prompt successful\n');

    // All passed
    console.log('='.repeat(60));
    console.log('✅ All tests passed!');
    console.log('='.repeat(60));
    console.log('');
    console.log('Your Gemini setup is working correctly.');
    console.log('You can now run:');
    console.log('  npm start   — run the demo');
    console.log('  npm run chat — start interactive chat');
    console.log('');

    geminiProc.kill();

  } catch (error) {
    console.error(`   ❌ ${error.message}\n`);

    if (error.message.includes('Authentication') || error.message.includes('401') || error.message.includes('403')) {
      console.error('Authentication issue. Set your API key:');
      console.error('  export GEMINI_API_KEY="your-api-key"');
      console.error('  Get key from: https://aistudio.google.com/apikey\n');
    } else if (error.message.includes('timeout')) {
      console.error('Connection timeout. Gemini CLI may be slow to start on first run.\n');
    } else {
      console.error('Unexpected error. Check your Gemini CLI installation:\n');
      console.error('  npm install -g @google/gemini-cli\n');
    }

    if (geminiProc) {
      geminiProc.kill();
    }

    process.exit(1);
  }
}

testGeminiConnection().catch(error => {
  console.error('\n❌ Fatal error:', error.message);
  process.exit(1);
});
