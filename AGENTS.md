# AGENTS.md

Instructions for coding agents working in this repository.

## What this repo is

A place to put things up so they can be shared with other people — Claude
artifacts, documents, static pages, files. Everything here is published to the
public web by GitHub Pages from `main`, at <https://kbenestad.github.io/shared/>.

The point of the repo is the link. Work is not finished when it is committed;
it is finished when it is live and the user has the URL to hand to someone.

## Pushing

When a change is good to go, it goes straight to `main`. No pull request, no
asking for confirmation, no waiting for review, no leaving work on a branch.

```
git add -A && git commit -m "..." && git push origin main
```

Then give the user the public URL for what you just published.

Branches are fine as scratch space, but nothing is delivered until it is on
`main`.

## Checking your work

Verify before pushing — then push immediately. Checking is not a reason to
pause and ask; it is what replaces the review step this repo deliberately
does not have.

- Confirm the thing actually works: open a page, exercise its buttons and
  inputs, check a file opens as the right type.
- Check pages at phone width as well as desktop.
- Version numbers, package names, URLs and commands a reader will paste into
  a terminal get checked against an authoritative source. Never reproduce
  them from memory.
- After pushing, fetch the live URL and confirm the new version is actually
  being served. Pages takes about a minute to rebuild.

## Publishing

Everything committed here becomes publicly readable and search-indexable, and
links that have been shared are hard to un-share. Before publishing a file the
user has supplied, read it and make sure it does not contain anything they
would not want public — keys, tokens, personal details, private correspondence.
Ask if something looks unintended for publication.

## Paths and file layout

A directory's `index.html` serves at that directory's path: `ppg/index.html`
is reachable at `/shared/ppg/`. Prefer `<name>/index.html` over `<name>.html`
— the directory-index convention resolves on any static host, whereas a bare
`.html` file only maps to an extensionless path because GitHub Pages silently
appends `.html`. Staying portable means the shared links survive a move off
GitHub.

Give things short, guessable path names. People type these.

## Editing an existing page

Pages here are often followed step by step, so a wrong command costs a reader
real time.

- Keep each page a single self-contained file with no external dependencies.
- Match the existing markup and style; do not restyle adjacent content.
- If a value appears in both visible text and a script or data attribute, make
  one the source of truth rather than updating both by hand.
