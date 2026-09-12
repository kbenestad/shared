# AGENTS.md

Instructions for coding agents working in this repository.

## What this repo is

Publicly available shared artifacts — mostly self-contained static HTML pages,
served by GitHub Pages from `main` at <https://kbenestad.github.io/shared/>.

A page in a directory is reachable at that directory's path. `ppg/index.html`
serves at `/shared/ppg/`. Prefer `<name>/index.html` over `<name>.html`: the
directory-index convention resolves on any static host, whereas a bare
`.html` file only maps to an extensionless path because GitHub Pages
silently appends `.html`. Keeping to the portable form means the URLs
survive a move off GitHub.

## Pushing

Push finished work straight to `main`. Do not open a pull request, do not ask
for confirmation, do not wait for review, do not leave work sitting on a
branch. There is no review gate here and creating one is wasted ceremony.

```
git add -A && git commit -m "..." && git push origin main
```

Branches are fine as scratch space, but the change is not delivered until it
is on `main`.

## Before you push

`main` is published to the public web within about a minute of the push, so
the push is the release. There is no reviewer between you and a live page.
That is the reason to verify first, not a reason to slow down:

- Open the page and confirm it renders — at phone width as well as desktop.
- Exercise anything interactive (buttons, inputs) rather than assuming it works.
- If the page contains version numbers, package names, URLs or commands a
  reader will paste into a terminal, check them against an authoritative
  source. Do not reproduce them from memory.

## Editing existing pages

These pages are read by people following along step by step, so a wrong
command costs a reader real time. When changing one:

- Keep the page a single self-contained file with no external dependencies.
- Match the existing markup and style; do not restyle adjacent content.
- If a value appears in both visible text and a script (or a data attribute),
  make one the source of truth rather than updating both by hand.
