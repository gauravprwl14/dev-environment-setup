---
name: skill-scaffold
description: "Generate a new Claude Code skill directory with SKILL.md, plugin.json, and optional scripts/. Use when creating a new skill from scratch."
argument-hint: 'skill-scaffold my-new-skill, skill-scaffold my-tool --with-python'
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Skill Scaffold — Generate New Claude Code Skills

Create a new skill directory with all required files following the project's skill conventions.

## Execution Logic

Check `$ARGUMENTS`:

- If **empty** → respond: "Skill Scaffold loaded. Usage: `/skill-scaffold <skill-name> [--with-python] [--with-scripts]`" and STOP.
- If **has arguments** → parse and execute below.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `SKILL_NAME` — first positional argument (e.g., `my-new-skill`)
- `--with-python` flag → create `scripts/` dir with a Python stub + `requirements.txt`
- `--with-scripts` flag → create `scripts/` dir with a bash stub

## Task Execution

1. **Determine output directory**: Use `skills/` relative to the current project root (where this skill is installed)

2. **Create directory structure**:
   ```
   skills/<SKILL_NAME>/
   ├── SKILL.md
   ├── .claude-plugin/
   │   └── plugin.json
   └── README.md
   ```
   If `--with-python`:
   ```
   └── scripts/
       ├── <skill_name>.py    (snake_case version)
       └── requirements.txt
   ```
   If `--with-scripts`:
   ```
   └── scripts/
       └── run.sh
   ```

3. **SKILL.md template** — generate with:
   ```yaml
   ---
   name: <SKILL_NAME>
   description: "<Ask user or use placeholder>"
   argument-hint: '<SKILL_NAME> <args>'
   allowed-tools: Bash, Read, Write, Edit
   ---

   # <SKILL_NAME>

   ## Execution Logic

   Check `$ARGUMENTS`:
   - If **empty** → respond with usage and STOP.
   - If **has arguments** → parse and execute.

   ## Task Execution

   [TODO: Define skill logic here]
   ```

4. **plugin.json template**:
   ```json
   {
     "name": "<SKILL_NAME>",
     "description": "<same as SKILL.md description>",
     "version": "1.0.0",
     "author": { "name": "gp" },
     "repository": "https://github.com/gp/dev-environment-setup",
     "license": "MIT",
     "skills": ["./"]
   }
   ```

5. **Python stub** (if `--with-python`):
   ```python
   #!/usr/bin/env python3
   """<SKILL_NAME> — [description]"""
   import sys

   def main():
       if len(sys.argv) < 2:
           print("Usage: <skill_name>.py <args>", file=sys.stderr)
           sys.exit(1)
       # TODO: implement
       print(f"Running {sys.argv[0]} with args: {sys.argv[1:]}")

   if __name__ == "__main__":
       main()
   ```

6. **README.md**:
   ```markdown
   # <SKILL_NAME>

   > [description]

   ## Usage

   `/<skill-name> <args>`

   ## Installation

   `npx skills i gp/dev-environment-setup --skill <skill-name>`
   ```

7. After creation, output:
   ```
   ✅ Skill "<SKILL_NAME>" created at skills/<SKILL_NAME>/

   Files:
   - SKILL.md (edit to define skill logic)
   - .claude-plugin/plugin.json
   - README.md
   [- scripts/<file> (if --with-python or --with-scripts)]

   Next: Edit SKILL.md to define your skill's behavior.
   ```
