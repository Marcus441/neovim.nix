---
paths: "docs/**"
---

# Pointer sync — what an entry owes the code that cites it

**The entry format and the pointer test live in `docs/README.md` and are not
restated here.** This file is the docs-side half of the contract: what to check
before touching anything under `docs/`.

## Anchors are API

A `# load-bearing: docs/<area>.md#anchor` pointer resolves against a `##`
heading's text — lowercased, spaces to hyphens, punctuation dropped. **Renaming
a heading breaks every pointer at it silently**; markdown anchors never error.
Before touching a heading under `docs/`, grep for its anchor:

```bash
grep -rn "docs/decisions/<file>.md#" modules/ docs/
```

Both trees, because entries cite each other — `modules/formatter.nix` points at
`overrides.md#a-formatter-command-needs-mkoverride-40`, and `formatters.md`
cites `overrides.md` in prose.

## The contract runs both ways

Code changes ⇒ entry changes in the same commit — that half is in
`docs/README.md`. The docs-side half: **editing an entry means re-checking that
the code it describes still matches**, and a **Breaks** line is a measurement,
not a guess. Rewording one into a claim nobody measured (a closure size, a
"silently") is how a register starts lying; keep the number, or re-measure it.

## The census is itself a drift hazard

`docs/README.md` enumerates which files carry pointers and how many ("Sixteen
files carry one today…"). A commit that adds or removes a pointer updates that
paragraph in the same commit, or the census is the first entry to drift.

## Deleting an entry

Only when the code it explains is gone. The pointer form is not the only
citation: rules and skills cite decision files by path (`settled-decisions.md`
and the add-language skill both cite `formatters.md`), so grep for the bare
filename too. Pointer, entry, and citations leave in one commit.

**A reversed decision is deleted, not marked "superseded".** History lives in
git — cite the commit that reversed it. An entry kept as a tombstone is exactly
the drifted register `docs/README.md` warns is worse than none.
