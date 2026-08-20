# decisions/openapi

## schemastore is fetched at runtime

**Why:** yaml-language-server reads `yaml.schemaStore.url` and pulls
SchemaStore's catalog over HTTP when it starts, then fetches each matched schema
the same way. Nothing here vendors either. The alternative was a `fetchurl` at a
pinned hash pointing at a `file://` path — hermetic, offline-proof, and the shape
`kotlin.nix` already uses for a whole server — but it buys one schema where the
catalog buys 1420, and the ones that earn their keep day to day are the
incidental catches: GitHub Actions workflows, `docker-compose.yml`, k8s
manifests, `.gitlab-ci.yml`. Pinning would have to enumerate them.

**Breaks:** silently, and it is the reason this entry exists. With no network the
server starts, attaches, reports healthy in `:LspInfo`, and validates nothing —
no error, no message, no diagnostic. An `openapi.yaml` full of typos looks
exactly like a clean one. The same is true behind a proxy that blocks
`schemastore.org`.

**Also:** this is the one runtime network dependency in the config, and it is
`dev`-only because the servers are. `min` never had validation to lose. The
telemetry opt-out beside it is nvf's, not this file's — nvf's yaml preset sets
`settings.redhat.telemetry.enabled = false`, and these settings merge with it
rather than replace it, which is also why neither assignment here needs a
`mkForce`.

## the catalog globs are narrow

**Why:** the explicit `schemas` blocks are not redundant with the catalog.
SchemaStore's own OpenAPI entry declares `fileMatch` as `openapi.json`,
`openapi.yml`, `openapi.yaml` and `*.openapi.*` and nothing else — verified
against the live catalog on 2026-08-20. A spec at `api/v1.yaml`, or split under
`docs/openapi/users.yaml`, matches none of them. The extra globs cover the two
layouts that are common and unmatched. `vscode-json-language-server` has no
schemaStore support of any kind, so its list is not a supplement but the whole
mechanism.

**Breaks:** silently, in the way that reads as success. A spec outside the globs
gets no completion and no validation, which is indistinguishable from a spec
that is simply correct. The tell is that `info:` offers no completion for
`title`.

**Also:** widening these is cheap and safe — an unmatched schema costs nothing —
but a glob broad enough to catch every `*.yaml` would validate ordinary config
files against the OpenAPI schema and bury them in errors. Narrow-and-extended
beats broad.

**Known wart:** every OpenAPI **3.1 JSON** spec carries one extra warning at line
1 — *"The schema uses meta-schema features ($dynamicRef) that are not yet
supported by the validator"*. It is vscode-json-language-server saying the 3.1
schema uses JSON Schema 2020-12 features it only partly implements; validation
still works, and the real errors appear beside it. yaml-language-server does not
emit it, so YAML specs are clean. Pointing JSON at the 3.0 schema would silence
it and mis-validate every 3.1 document — a bad trade for one warning.
