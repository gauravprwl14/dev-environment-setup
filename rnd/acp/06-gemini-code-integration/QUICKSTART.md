# Quickstart: Gemini ACP Integration

## 1. Install dependencies

```bash
cd 06-gemini-code-integration
npm install
```

## 2. Install the Gemini CLI

```bash
npm install -g @google/gemini-cli
```

> **No global install?** The scripts fall back to `npx @google/gemini-cli` automatically.

## 3. Set your API key

```bash
export GEMINI_API_KEY="your-api-key"
```

Get a free key at: https://aistudio.google.com/apikey

## 4. Run

```bash
# Verify everything works
npm test

# Demo script
npm start

# Interactive chat (recommended)
npm run chat
```
