---
name: content-summarizer
description: "Generate a structured summary from a YouTube transcript or any long-form content. Use after /yt-transcript."
argument-hint: 'content-summarizer path/to/transcript.md'
allowed-tools: Read, Write
---

# Content Summarizer

Generate a deep, structured summary from transcript or long-form content.

## Execution Logic

Check `$ARGUMENTS`:
- If **empty** → respond: "Content Summarizer loaded. Usage: `/content-summarizer <path-to-transcript.md>`" and STOP.
- If **has arguments** → treat as file path to transcript and execute below.

## Task Execution

1. **Read the transcript** at the path provided in `$ARGUMENTS` using the Read tool.

2. **Extract YAML frontmatter** — capture title, channel, URL, duration for context.

3. **Generate structured summary** with this exact format:

```markdown
---
title: "<from transcript>"
channel: "<from transcript>"
url: "<from transcript>"
duration: "<from transcript>"
date_summarized: "<today YYYY-MM-DD>"
type: content-summary
---

# Summary: <Title>

## Thesis
[1-2 sentence core argument/message of the content]

## Key Topics
[For EACH major topic discussed:]
### <Topic Name>
- **What:** [Clear explanation]
- **Why it matters:** [Significance]
- **Key details:** [Supporting points, data, examples]

## Notable Quotes
> "[Exact or near-exact memorable quotes from the content]"
> — <Speaker/Channel>

[Include 3-5 most impactful quotes]

## Key Takeaways
1. [Actionable insight #1]
2. [Actionable insight #2]
3. [Continue for all major takeaways]

## Target Audience
- [Who would benefit most from this content]
- [Prerequisites or assumed knowledge]

## Tone & Style
- [Describe the content's tone: educational, conversational, technical, etc.]
- [Notable presentation style elements]

## Content Metadata
- **Word count:** ~<transcript word count>
- **Key themes:** <comma-separated themes>
- **Complexity:** <beginner | intermediate | advanced>
```

4. **Save output** to the same directory as the transcript file, named `summary.md`.

5. **Report results**:
```
✅ Summary generated: <title>
📁 Saved to: <path>/summary.md
📊 <N> key topics | <N> takeaways | <N> quotes

Next: Run `/obsidian-note <path>/summary.md` or `/content-ideas <path>/summary.md`
```

## Quality Rules
- Extract EVERY distinct topic — do not merge or skip
- Quotes must be actual quotes from the transcript, not paraphrased
- Takeaways must be actionable, not generic platitudes
- If the transcript is very short (<500 words), note this and adjust depth accordingly
