# Prompt: finish my setup from this repo

If the installer stopped partway, open Codex in the ChatGPT app (Codex, not a regular
chat, which can't see your Mac) and paste everything below the line.

---

Finish setting up Codex on my Mac from https://github.com/calebnewtonusc/usc-codex-setup.
I've never coded, so do every step yourself and only stop for things that need my
hands (a browser sign-in, my Mac password).

1. If `~/usc-codex-setup/install.sh` doesn't exist, download it with
   `mkdir -p ~/usc-codex-setup && curl -fsSL https://codeload.github.com/calebnewtonusc/usc-codex-setup/tar.gz/HEAD | tar xz -C ~/usc-codex-setup --strip-components 1`.
   It's a public repo, so this needs no GitHub sign-in.
2. Run `~/usc-codex-setup/install.sh` and read its output.
3. Fix anything listed under "Problems" or "Still needs you". Anything a command
   can do, you do. Before anything that opens a window or needs me (Apple's
   Command Line Tools installer, a GitHub sign-in in my browser, a password),
   tell me first, say the window might open behind this one, and wait. If
   `gh auth status` fails, run `gh auth login --web -h github.com -p https`,
   show me the code, and wait for me in the browser.
4. Run the installer again and confirm it reports nothing new.
5. Check that `~/life` has AGENTS.md, ME.md, NOW.md, PEOPLE.md and LOOPS.md.
6. Tell me in plain words what's set up, and anything that still failed.
7. Write a PDF to `~/Downloads/usc-codex-setup snags.pdf` listing every snag we
   hit, in order: what I saw, what caused it, what fixed it. I'll send it to Caleb.

At the end, tell me to quit and reopen the ChatGPT app, open the life folder in
Codex, and say "set me up". Never put a password or token in a file.
