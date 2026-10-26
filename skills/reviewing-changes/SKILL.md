---
name: reviewing-changes
description: "Review code for real problems before it goes anywhere. Use for review this, check for bugs, is this safe to merge, review my PR, before opening a PR, after a feature, or when called sloppy."
---

# Reviewing changes

Find real problems. Style opinions waste the one pass someone will actually read,
and a review that opens on naming teaches the author that reviews are noise.

The agent owns routine review and repair. Don't hand the diff to the user as a
required step. Fix substantiated findings inside the task's scope, rerun the
affected checks, then review the changed result once more.

## The pass, in order

1. `git diff --stat` and `git diff` against the base (`main` or the last commit you
   didn't write). Read every hunk. Never comment on code you haven't read.
2. Run the deterministic checks first, they cost nothing:
   - `npx tsc --noEmit` (or the project's typecheck script)
   - `code-slop --issues` on the diff
   - `slop-check <changed .md files> --issues`
   - the project's tests, if it has them
3. Then read for, in this order of cost:
   - **Correctness.** Wrong branch taken, off by one, null not handled, an await
     missing, a promise fired and forgotten, an error swallowed in an empty catch.
   - **Security.** User input in SQL or a shell string, a secret in source or logs,
     a user-supplied id trusted without an ownership check, `dangerouslySetInnerHTML`
     without a sanitizer.
   - **Contracts.** A type, enum, route or schema changed here but not at every caller.
   - **Tests.** A bug fix with no test that would have caught it.
4. For each finding: file and line, the concrete input or state that breaks, and
   the fix. A finding without a failure scenario is an opinion, drop it.
5. Fix what's in scope, rerun step 2, and say plainly what's left.

## What a finding looks like

```
lib/store.ts:42  getUser returns undefined when the phone has a leading +,
                 so a WhatsApp message from +1 310... creates a duplicate user.
                 Normalize with the same helper bridge/ uses before the lookup.
```

## What not to report

- Naming, formatting, import order: the formatter and linter own those.
- "Consider adding error handling" with no input that reaches the missing path.
- Anything outside the diff, unless the diff makes it newly reachable.

## Second opinion

For a risky change (auth, payments, data deletion, anything public), get an
independent read: start a fresh Codex session, give it only the diff and the
question "what input breaks this", and compare its findings with yours. Don't give
it your conclusion first, or it will agree with you.
