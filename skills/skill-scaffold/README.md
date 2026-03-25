# skill-scaffold

Generate a new Claude Code skill directory with all required files, following the project's skill conventions.

## Usage

```
# Basic skill (Read/Write only, no scripts)
/skill-scaffold my-new-skill

# With Python script
/skill-scaffold my-new-skill --with-python

# With shell script
/skill-scaffold my-new-skill --with-scripts
```

## What it creates

**Basic:**
```
skills/my-new-skill/
├── SKILL.md                    ← Execution instructions for Claude
├── README.md                   ← Human-readable docs
└── .claude-plugin/
    └── plugin.json             ← Skill metadata
```

**With --with-python:**
```
└── scripts/
    ├── main.py                 ← Python script stub
    └── requirements.txt        ← Python dependencies
```

**With --with-scripts:**
```
└── scripts/
    └── main.sh                 ← Shell script stub
```

## After scaffolding

1. Edit `SKILL.md` — add your execution logic
2. Edit `README.md` — document usage and output
3. Register in `skills/.claude-plugin/plugin.json` — add `"./my-new-skill"` to the `skills` array
4. Reinstall skills: `npx skills install ./skills --yes`

## Who it's for

Developers adding new skills to this pipeline. Not needed for using existing skills.
