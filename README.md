# usc-codex-setup

Every USC student can get Codex free through their USC ChatGPT account. This repo
turns it into something that runs your semester with you: it knows your classes,
deadlines, goals and people, tells you what to do today, walks you through any
application, and writes without sounding like AI. Made for students who've never
coded. Twenty minutes on a Mac.

Step-by-step guide with every link, including the USC form for Codex access:
https://docs.google.com/document/d/1bjF9hRJYw4un9agw6SMMl2lb5bJG0-NKBWcqnF5sfk8

If it helps you, star the repo and send the guide to a friend.
## Before you start

You need three things. The full walkthrough with every link is in the Google Doc
that came with this repo.

- A GitHub account (free): https://github.com/signup. GitHub saves your setup and
  anything you build, with every version kept.
- Codex access through your USC ChatGPT account. Request it with the USC ITS form:
  https://itsusc.service-now.com/usc_its_support?id=sc_cat_item&sys_id=3815a5fd879c87505edaa7583cbb354d
- Homebrew, Codex and GitHub's tool. Paste these into Terminal one at a time:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install node gh
gh auth login
```

And download the ChatGPT app for Mac (https://learn.chatgpt.com/docs/app), signed in with your USC account. That's where you use Codex. Terminal is only for setup.

## Install

```bash
gh repo clone calebnewtonusc/usc-codex-setup ~/usc-codex-setup && ~/usc-codex-setup/install.sh
```

Then quit and reopen the ChatGPT app, go to Codex, and open the `life` folder in your home folder. Say "set me up". It interviews you one question at a time and fills in your files.
After that, open that folder and ask "what should I do today."

Running the installer twice adds nothing the second time, and it never overwrites a
file you already have. `./install.sh --dry-run` shows what it would do first.

## What you get

- **~/life**, your folder: `ME.md` (who you are), `NOW.md` (classes, deadlines),
  `PEOPLE.md`, `LOOPS.md` (everything you said you'd do), and an `AGENTS.md` that
  tells Codex how to use them. It's tracked with git, so any change can be undone.
- **Skills** Codex picks up on its own: life-ops (planning a week, appointments,
  renewals, forms, the Sunday review), grilling (for when you're stuck on a
  decision), deep-research, reflect, and writing editors that strip AI tells
  (no-ai-slop, avoid-ai-writing, humanizer). For when you start building things:
  debugging, reviewing-changes, shipping, interface, repo-health, stack-rules,
  plus pdf, docx and xlsx from Anthropic's skills repo.
- **Kits** Codex clones when you need one: [apply-kit](https://github.com/calebnewtonusc/apply-kit)
  for any application (clubs, jobs, fellowships), [accommodations-kit](https://github.com/calebnewtonusc/accommodations-kit)
  for disability accommodations, [claude-design-kit](https://github.com/calebnewtonusc/claude-design-kit)
  for making things look designed.
- More skills: diagram (clean diagrams of anything), first-reader (reads a draft
  the way its reader will), thinking-out-loud, and pptx for slides.
- **Checks**: `slop-check <file> --issues` scores a draft for AI-sounding writing.
  `ai-scan`, `code-slop` and `agent-check` do the same for words and code.
- **Tools Codex can use**: a headless browser (playwright, chrome-devtools), web
  fetch, current library docs (context7), git and GitHub.

## Flags

`--no-prereqs`, `--no-skills`, `--no-mcp`, `--no-config`, `--no-life`, `--dry-run`.
`bash tests/smoke.sh` runs the installer in an empty home folder twice and checks
the second run adds nothing.

## Uninstall

- Delete `~/.local/share/usc-codex-setup` and the links pointing into it from
  `~/.agents/skills` and `~/.local/bin`.
- Delete the block between the `usc-codex-setup` markers in `~/.codex/AGENTS.md`
  and the `slop-after-edit.py` entry in `~/.codex/hooks.json`.
- `~/life` is yours. Keep it or delete it.

## Sources

- [petergyang/no-ai-slop](https://github.com/petergyang/no-ai-slop), [conorbronsdon/avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing), [blader/humanizer](https://github.com/blader/humanizer)
- [31Carlton7/skills](https://github.com/31Carlton7/skills): deslop
- [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design): diagram
- [Shubhamsaboo/awesome-llm-apps](https://github.com/Shubhamsaboo/awesome-llm-apps): first-reader, thinking-out-loud
- [anthropics/skills](https://github.com/anthropics/skills): document and dev skills
- The rest: ported from Caleb Newton's own kit

All glory to God! ✝️❤️
