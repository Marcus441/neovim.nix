# decisions/typescript

## tsx declines biome and keeps eslint_d

**Why:** nvf splits React off into its own `vim.languages.tsx` module — the
sole source of the `typescriptreact` and `javascriptreact` filetypes, the `tsx`
grammar, and the conform routing for both. Enabling it under `dev` also
inherits `enableExtraDiagnostics = true` from `languages/every-language.nix`,
and tsx's `extraDiagnostics.types` enum offers exactly one linter: `biomejs`.
Its preset pins `pkgs.biome` and — unlike the eslint_d preset — carries no
`required_files` gate, so it would run on every React buffer, configured or
not. eslint_d, the linter this repo deliberately runs on `.ts`, is not
selectable there, so it is routed to the two React filetypes through the raw
`linters_by_ft` keys instead; the preset it rides on already requires an eslint
config in the project before it fires.

**Breaks:** silently, in both directions. Deleting `extraDiagnostics.enable =
false` builds fine and opts React files into an ungated biome, pinning it into
`dev`. Deleting the `linters_by_ft` block strips eslint from `.tsx` while `.ts`
keeps it, with no error anywhere — and React files are where eslint's rules
matter most.

**Also:** this is `data-languages.md#the-linters-stay-off` meeting
`#templates-yaml-becomes-a-gitlab-filetype`: the default linter is declined the
way scss declines stylelint, and the deliberate one is routed additively the
way chart templates reach prettier. If a future nvf pin adds `eslint_d` to
tsx's enum, the two raw lines collapse into `extraDiagnostics.types =
["eslint_d"]`. The routing rides on nvim-lint being enabled at all, which
typescript's own `extraDiagnostics` block in the same file provides — turn that
off and these lines go quietly inert with it.
