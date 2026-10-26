# Prompt: finish my setup from this repo

If the installer stopped partway, open Codex in the ChatGPT app and paste everything
below the line.

---

Finish setting up Codex on my Mac from https://github.com/calebnewtonusc/usc-codex-setup.
I've never coded, so do every step yourself and only stop for things that need my
hands (a browser sign-in, my Mac password).

1. If `~/usc-codex-setup` doesn't exist, run `gh repo clone calebnewtonusc/usc-codex-setup ~/usc-codex-setup`.
2. Run `~/usc-codex-setup/install.sh` and read its output.
3. Fix anything listed under "Problems" or "Still needs you". If `gh auth status`
   fails, run `gh auth login --web` and wait for me in the browser.
4. Run the installer again and confirm it reports nothing new.
5. Check that `~/life` has AGENTS.md, ME.md, NOW.md, PEOPLE.md and LOOPS.md.
6. Tell me in plain words what's set up, and anything that still failed.

At the end, tell me to quit and reopen the ChatGPT app, open the life folder in
Codex, and say "set me up". Never put a password or token in a file.
