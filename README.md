# usc-codex-setup

Every USC student can get Codex free through their USC ChatGPT account. This repo
turns it into something that runs your semester with you: it knows your classes,
deadlines, goals and people, tells you what to do today, walks you through any
application, and writes without sounding like AI. Made for students who've never
coded. Twenty minutes on a Mac.

Step-by-step guide with every link, including the USC form for Codex access:
https://docs.google.com/document/d/1bjF9hRJYw4un9agw6SMMl2lb5bJG0-NKBWcqnF5sfk8

If it helps you, star the repo and send the guide to a friend.

## Start here: where you type

Two places, and only two.

- **Terminal, once, for the setup line below.** Codex isn't set up on your Mac
  yet, so this one step can't happen inside it. Open Terminal with Command and
  Space, type `Terminal`, press Enter.
- **Codex in the ChatGPT app, for everything after.** Download the ChatGPT app
  for Mac (https://learn.chatgpt.com/docs/app) and sign in with your USC account.
  Use Codex there, not a regular ChatGPT chat. A regular chat can't see the files
  on your Mac, so it'll tell you to connect GitHub or upload files. You don't need
  either.

Paste this one line into Terminal and press Enter. It downloads this repo and runs
the whole setup, no Homebrew or GitHub sign-in needed first:

```bash
mkdir -p ~/usc-codex-setup && curl -fsSL https://codeload.github.com/calebnewtonusc/usc-codex-setup/tar.gz/HEAD | tar xz -C ~/usc-codex-setup --strip-components 1 && bash ~/usc-codex-setup/install.sh
```

It stops for you in three places. Each one can open a window behind Terminal, so
if nothing seems to happen, press Command-Tab and look:

- **Apple's Command Line Tools** (only on a Mac that's never had them). A window
  asks to install them. Click Install, wait for it to finish, then paste the same
  line again.
- **GitHub sign-in.** It shows a code like `ABCD-1234`. Copy it, press Enter, and
  your web browser opens to GitHub. If it asks you to sign in first, do that,
  and the page for the code comes next. Paste the code, click Authorize, then
  come back to Terminal.
- **Codex's hook check**, possibly, the first time you open Codex after setup.
  If it asks whether to trust a new hook from usc-codex-setup, say yes. That's
  the check that flags AI-sounding writing.

Then quit and reopen the ChatGPT app, go to Codex, open the `life` folder in your
home folder, and say "set me up". If the setup line stopped partway or printed
anything under "Problems", paste the prompt in [SETUP-FOR-CODEX.md](SETUP-FOR-CODEX.md)
into Codex and it finishes the job.

**If you're one of the first people through:** when you're done, tell Codex
"write a PDF to my Downloads folder listing every snag I hit setting this up, in
order, with what fixed each one" and send that PDF to Caleb.

## Before you start

- A GitHub account (free): https://github.com/signup. GitHub saves your setup and
  anything you build, with every version kept. Make it before you paste the
  setup line, so the sign-in step has an account to sign in to.
- Codex access through your USC ChatGPT account. Request it with the USC ITS form:
  https://itsusc.service-now.com/usc_its_support?id=sc_cat_item&sys_id=3815a5fd879c87505edaa7583cbb354d
- The ChatGPT app for Mac, signed in with your USC account (link above).

You don't need Homebrew. If you already have it, the installer uses it; if not,
it puts every tool in `~/.local` with no password.

## Install

The setup line under "Start here" is the whole install. It's the same as:

```bash
bash ~/usc-codex-setup/install.sh
```

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
