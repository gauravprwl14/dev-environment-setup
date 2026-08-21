/**
 * Test Connection to ACP-Compatible Agents
 * 
 * OpenClaw uses SPECIAL ACP-compatible wrappers for agents:
 * - Claude: @agentclientprotocol/claude-agent-acp (NOT the standard claude CLI)
 * - Codex: @agentclientprotocol/codex-acp
 * - OpenCode: opencode-ai acp
 * 
 * This test shows how to use these properly.
 */

import { spawn, execSync } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { ClientSideConnection, ndJsonStream, PROTOCOL_VERSION } from '@agentclientprotocol/sdk';

// ACP-compatible commands from OpenClaw's actual configuration
// Note: These packages were moved from @zed-industries to @agentclientprotocol
const ACP_AGENTS = {
  codex: {
    command: 'npx',
    args: ['@agentclientprotocol/codex-acp'],
    display: 'Codex (OpenAI)'
  },
  claude: {
    command: 'npx',
    args: ['-y', '@agentclientprotocol/claude-agent-acp'],
    display: 'Claude (Anthropic via ACP wrapper)'
  },
  opencode: {
    command: 'npx',
    args: ['-y', 'opencode-ai', 'acp'],
    display: 'OpenCode'
  }
};

async function testClaudeConnection() {
  console.log('');
  console.log('='.repeat(60));
  console.log('🧪 Testing ACP-Compatible Agent Connection');
  console.log('='.repeat(60));
  console.log('');
  
  console.log('ℹ️  OpenClaw uses special ACP-compatible wrappers:');
  console.log('   • Claude: @agentclientprotocol/claude-agent-acp');
  console.log('   • Codex: @agentclientprotocol/codex-acp');
  console.log('   • NOT the standard `claude` CLI!');
  console.log('');

  // Test 1: Check if npx is available
  console.log('1️⃣  Checking if npx is available...');
  
  try {
    execSync('npx --version', { stdio: 'pipe' });
    console.log('   ✅ npx is available\n');
  } catch (error) {
    console.error('   ❌ npx not found. Install Node.js/npm first.\n');
    process.exit(1);
  }

  // Test 2: Try to connect to an ACP-compatible agent
  console.log('2️⃣  Testing ACP connection with Claude wrapper...');
  console.log('   (This will download @agentclientprotocol/claude-agent-acp if needed)');
  console.log('');
  
  const agentConfig = ACP_AGENTS.claude;
  let claudeProc = null;
  let client = null;
  
  try {
    // Spawn the ACP-compatible Claude wrapper
    claudeProc = spawn(agentConfig.command, agentConfig.args, {
      stdio: ['pipe', 'pipe', 'inherit'],
      env: process.env
    });

    if (!claudeProc.stdin || !claudeProc.stdout) {
      throw new Error('Failed to create stdio pipes');
    }

    const input = Writable.toWeb(claudeProc.stdin);
    const output = Readable.toWeb(claudeProc.stdout);
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

    console.log('   ✅ ACP connection established\n');

    // Test 3: Initialize protocol
    console.log('3️⃣  Testing protocol initialization...');
    
    await client.initialize({
      protocolVersion: PROTOCOL_VERSION,
      clientCapabilities: {
        fs: { readTextFile: true, writeTextFile: true },
        terminal: true,
      },
      clientInfo: {
        name: 'claude-test',
        version: '1.0.0'
      }
    });

    console.log(`   ✅ Protocol initialized (version: ${PROTOCOL_VERSION})\n`);

    // Test 4: Create a test session
    console.log('4️⃣  Creating test session...');
    
    const session = await client.newSession({
      cwd: process.cwd(),
      mcpServers: []
    });

    console.log(`   ✅ Session created: ${session.sessionId}\n`);

    // Test 5: Send a simple prompt
    console.log('5️⃣  Testing prompt (with 5s timeout)...');
    
    // Correct ACP format: prompt is an array of ContentBlock objects
    const promptPromise = client.prompt({
      sessionId: session.sessionId,
      prompt: [
        {
          type: 'text',
          text: 'Respond with just "Hello" and nothing else'
        }
      ]
    });

    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Prompt timeout')), 5000)
    );

    await Promise.race([promptPromise, timeoutPromise]);

    console.log('   ✅ Prompt successful\n');

    // Success!
    console.log('='.repeat(60));
    console.log('✅ All tests passed!');
    console.log('='.repeat(60));
    console.log('');
    console.log('Your Claude Code setup is working correctly.');
    console.log('You can now run: npm start');
    console.log('');

    // Cleanup
    if (claudeProc) {
      claudeProc.kill();
    }

  } catch (error) {
    console.error(`   ❌ ${error.message}\n`);
    
    if (error.message.includes('Authentication') || error.message.includes('401')) {
      console.error('Authentication issue. Please run: claude setup-token\n');
    } else if (error.message.includes('timeout')) {
      console.error('Connection timeout. Claude may be slow to respond.\n');
    } else {
      console.error('Unexpected error. Check your Claude installation.\n');
    }
    
    if (claudeProc) {
      claudeProc.kill();
    }
    
    process.exit(1);
  }
}

// Run the test
testClaudeConnection().catch(error => {
  console.error('\n❌ Fatal error:', error.message);
  process.exit(1);
});
