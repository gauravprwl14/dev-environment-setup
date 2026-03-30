# Example 2: Channel & Thread Bindings

## What This Example Shows

How OpenClaw maps messages from different channels (Discord, Telegram, Slack) to the right agent sessions.

**The Problem**: You have messages coming from multiple places:
- Discord channel #dev
- Telegram group "Team Chat"
- Slack DM with Sarah

**The Solution**: Channel bindings route each to the correct session.

## The Routing Flow

```
┌──────────────┐         ┌──────────────────┐         ┌──────────────┐
│   Discord    │         │  Binding Manager │         │  ACP Session │
│  Channel A   │-------->│                  │-------->│  Session 1   │
└──────────────┘         │  - Routes based  │         └──────────────┘
                         │    on config     │
┌──────────────┐         │  - Maintains     │         ┌──────────────┐
│   Telegram   │-------->│    mappings      │-------->│  ACP Session │
│   Group B    │         │  - Creates new   │         │  Session 2   │
└──────────────┘         │    if needed     │         └──────────────┘
                         └──────────────────┘
┌──────────────┐                  |                  ┌──────────────┐
│    Slack     │------------------+----------------->│  ACP Session │
│   Channel C  │                                     │  Session 3   │
└──────────────┘                                     └──────────────┘
```

## Binding Types

### 1. Persistent Bindings (Config-based)

**What**: Permanently mapped in your config file
**When**: For stable, long-term conversations

```json
{
  "bindings": [{
    "type": "acp",
    "match": {
      "channel": "discord",
      "peer": { "id": "1234567890" }
    },
    "agentId": "main",
    "acp": {
      "mode": "persistent",
      "backend": "codex"
    }
  }]
}
```

**Result**: All messages from Discord channel `1234567890` always go to the same Codex ACP session.

### 2. Dynamic Bindings (Runtime)

**What**: Created on-the-fly when someone requests it
**When**: For temporary or thread-specific conversations

**User says**: `/acp spawn codex --thread`

**Result**: OpenClaw creates a binding just for that thread, right now.

## Code Example

### Binding Manager (binding-manager.js)

```javascript
class BindingManager {
  constructor() {
    // Store active bindings
    this.bindings = new Map();
    // Track persistent (config) vs dynamic (runtime)
    this.persistentBindings = new Map();
  }

  /**
   * Add a persistent binding from config
   */
  addPersistentBinding(spec) {
    const bindingId = this.createBindingId(spec);
    const sessionKey = this.createSessionKey(spec);
    
    const binding = {
      id: bindingId,
      conversation: {
        channel: spec.channel,
        accountId: spec.accountId,
        conversationId: spec.conversationId
      },
      targetSessionKey: sessionKey,
      mode: spec.mode,
      backend: spec.backend,
      source: 'config',
      boundAt: Date.now()
    };
    
    this.persistentBindings.set(bindingId, binding);
    this.bindings.set(bindingId, binding);
    
    return binding;
  }

  /**
   * Create a dynamic binding (like from /acp spawn)
   */
  createDynamicBinding(spec) {
    const bindingId = this.createBindingId(spec);
    const sessionKey = this.createSessionKey(spec);
    
    const binding = {
      id: bindingId,
      conversation: {
        channel: spec.channel,
        accountId: spec.accountId,
        conversationId: spec.conversationId
      },
      targetSessionKey: sessionKey,
      mode: spec.mode,
      backend: spec.backend,
      source: 'dynamic',
      boundAt: Date.now()
    };
    
    this.bindings.set(bindingId, binding);
    
    return binding;
  }

  /**
   * Find which session a message should go to
   */
  resolveBinding(channel, accountId, conversationId) {
    const bindingId = this.createBindingId({
      channel,
      accountId,
      conversationId
    });
    
    return this.bindings.get(bindingId);
  }

  /**
   * Create a unique binding ID
   */
  createBindingId(spec) {
    return `${spec.channel}:${spec.accountId}:${spec.conversationId}`;
  }

  /**
   * Create a session key for this binding
   */
  createSessionKey(spec) {
    const hash = this.hashConversation(spec);
    return `agent:${spec.agentId || 'main'}:acp:${spec.channel}:${hash}`;
  }

  /**
   * Simple hash function
   */
  hashConversation(spec) {
    const str = `${spec.channel}:${spec.accountId}:${spec.conversationId}`;
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash).toString(16).substring(0, 8);
  }
}
```

## Running the Example

```bash
cd 02-channel-binding
npm install
npm start
```

**Expected output:**

```
🔗 Channel Binding Demo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 STEP 1: Setting up persistent bindings from config
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Added binding: discord:bot-123:channel-dev
   → Session: agent:main:acp:discord:a1b2c3d4
✅ Added binding: telegram:bot-456:group-team
   → Session: agent:main:acp:telegram:e5f6g7h8

📍 STEP 2: Message from Discord #dev
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Looking up binding for: discord:bot-123:channel-dev
✅ Found binding! Routing to: agent:main:acp:discord:a1b2c3d4
💬 Sending message to session...
   Session handle: SessionHandle { sessionKey: 'agent:main:acp:discord:a1b2c3d4', ... }

📍 STEP 3: Message from Telegram Team Chat
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Looking up binding for: telegram:bot-456:group-team
✅ Found binding! Routing to: agent:main:acp:telegram:e5f6g7h8
💬 Sending message to session...

📍 STEP 4: Creating dynamic binding (like /acp spawn)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User in Discord thread says: /acp spawn claude --thread
✅ Created dynamic binding: discord:bot-123:thread-999
   → Session: agent:main:acp:discord:i9j0k1l2
💬 Sending message to new session...

📍 STEP 5: Viewing all bindings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Active Bindings:
  1. [config] discord:bot-123:channel-dev
     Target: agent:main:acp:discord:a1b2c3d4
  2. [config] telegram:bot-456:group-team
     Target: agent:main:acp:telegram:e5f6g7h8
  3. [dynamic] discord:bot-123:thread-999
     Target: agent:main:acp:discord:i9j0k1l2

🎉 Demo Complete!
```

## Real-World Scenarios

### Scenario 1: Team Dev Channel

**Setup (config)**:
```json
{
  "bindings": [{
    "type": "acp",
    "match": {
      "channel": "discord",
      "peer": { "id": "dev-channel-id" }
    },
    "agentId": "main",
    "acp": {
      "mode": "persistent",
      "backend": "codex",
      "label": "Team Dev Bot"
    }
  }]
}
```

**What happens**:
- Any message in #dev-channel → Goes to same persistent Codex session
- All team members share the same conversation history
- Agent remembers previous discussions

### Scenario 2: Per-Thread Support

**Setup**: No config needed, created dynamically

**User action**: In Discord thread about bug #123, someone says:
```
/acp spawn claude --thread auto --label "Bug 123 Investigation"
```

**What happens**:
1. OpenClaw creates a new binding for this specific thread
2. All messages in this thread now go to a dedicated Claude session
3. Other threads are unaffected
4. When thread is closed/archived, binding can be cleaned up

### Scenario 3: Multi-Account Routing

**Setup**:
```json
{
  "bindings": [
    {
      "match": {
        "channel": "telegram",
        "peer": { "id": "work-chat" }
      },
      "acp": {
        "backend": "codex",
        "cwd": "/Users/you/work-projects"
      }
    },
    {
      "match": {
        "channel": "telegram",
        "peer": { "id": "personal-chat" }
      },
      "acp": {
        "backend": "claude",
        "cwd": "/Users/you/personal-projects"
      }
    }
  ]
}
```

**What happens**:
- Work chat uses Codex in work directory
- Personal chat uses Claude in personal directory
- Completely isolated conversations

## How Sessions are Keyed

Session keys follow a pattern:

```
agent:<agentId>:acp:<channel>:<hash>
```

**Examples**:
- `agent:main:acp:discord:a1b2c3d4` - Discord binding
- `agent:main:acp:telegram:e5f6g7h8` - Telegram binding
- `agent:work:acp:slack:i9j0k1l2` - Slack binding for "work" agent

**The hash** is derived from `channel:accountId:conversationId` so the same conversation always maps to the same session.

## Key Takeaways

1. **Bindings map conversations to sessions**: One conversation → One session
2. **Persistent bindings** survive restarts (from config)
3. **Dynamic bindings** are created at runtime (like /acp spawn)
4. **Session keys** are deterministic (same input = same key)
5. **Multiple channels** can coexist without interfering

## Next Steps

- **Example 3**: Learn how long-term session management works
- **Example 4**: Explore how tool calls flow through bindings
- **Example 5**: See the complete integration

---

🔗 [← Back](../01-simple-message-flow/) | [Main README](../README.md) | [Next: Session Management →](../03-session-management/)
