# CI/pipeline fixes log — QEMU32_RISCV_PicoJPEG

A chronological record of every real failure hit turning this pack's CI green, with the
exact symptom, root cause, and fix commit. `docs/creating-a-cmsis-pack.md` folds the
durable lessons from this into a forward-looking guide; this file is the incident-by-
incident detail behind it, kept as a reference for anyone debugging a similar pack.

## 1. `gen_pack.sh` not executable → exit code 126

**Symptom** (build job, "Validate and build pack" step):
```
Process completed with exit code 126.
```

**Root cause:** `gen-pack-action` runs the script as `./gen_pack.sh` (direct execution),
not `bash ./gen_pack.sh`. The file was created via an editor/write tool and never
`chmod +x`'d before the first commit, so git tracked it as mode `100644`. Exit 126 means
"found the command, couldn't execute it" — the classic missing-execute-bit symptom.

**Diagnosis:** `git ls-files -s QEMU32_RISCV_PicoJPEG/gen_pack.sh` showed `100644`.

**Fix** (`d19fc8a`):
```
git update-index --chmod=+x QEMU32_RISCV_PicoJPEG/gen_pack.sh
```
Confirmed mode changed to `100755`, committed.

## 2. `actions/checkout@v4` etc. targeting deprecated Node.js 20

**Symptom:** GitHub warning banner on the run:
```
Node.js 20 is deprecated. The following actions target Node.js 20 but are being
forced to run on Node.js 24: actions/checkout@v4.
```

**Root cause:** pinned action majors (`actions/checkout@v4`, `actions/upload-pages-
artifact@v3`, `actions/deploy-pages@v4`) predate each action's Node 24 runtime bump.
Not fatal (GitHub forces Node 24 anyway), but a warning worth clearing.

**Fix** (`3786b16`): checked each action's latest release via the GitHub API and bumped
to the current Node-24-native majors: `checkout@v7`, `upload-pages-artifact@v5`,
`deploy-pages@v5`.

## 3. pdsc schema requires `<example><board>` — packchk alone didn't catch it

**Symptom** (build job, "Validate and build pack" step):
```
.../Ashling.QEMU32_RISCV_PicoJPEG.pdsc:35: element project: Schemas validity error :
Element 'project': This element is not expected. Expected is ( board ).
.../Ashling.QEMU32_RISCV_PicoJPEG.pdsc fails to validate
gen_pack.sh> build aborted: Schema check of .../Ashling.QEMU32_RISCV_PicoJPEG.pdsc
against /tmp/PACK.xsd failed!
```

**Root cause:** an earlier fix (see `f6e42b6`, before this pack had CI at all) had
removed the pdsc's `<boards>` section entirely to dodge `packchk`'s M375 error ("No
mountedDevices for Board found") — reasoned that Open-CMSIS-Pack has no RISC-V device
representation, so no board could be declared "correctly" anyway. That reasoning missed
that `PACK.xsd`'s `ExampleType` makes `<board>` a **required** child element (at least
one, before `<project>`) — not optional. `packchk`'s own bundled "Xerxes schema check"
reported 0 errors both with and without `<boards>` present, so it never caught this;
only the CI step that runs `xmllint --schema` against the real, separately-fetched XSD
did.

**Investigation:** fetched `PACK.xsd` (the same `v1.7.7` version this pdsc declares) and
read `ExampleType`, `BoardType`, `BoardsDeviceType` (mountedDevice), `DeviceType`, and
`DeviceVendorEnum`/`DcoreEnum` directly. Confirmed:
- `<example>` sequence is `description, board+ (required), project, attributes`.
- `DcoreEnum` includes an explicit `other` value — the spec's own escape hatch for
  non-Arm cores. This does not imply CMSIS-Toolbox can build for it (see
  `creating-a-cmsis-pack.md` step 0) — it only satisfies the schema/metadata model.
- `DeviceVendorEnum` includes `Generic:5` — a valid placeholder vendor code.

**Fix** (`a5bc25c`): added back a real `<devices>` entry (`Dvendor="Generic:5"`,
`Dcore="other"`, a `<memory>` region matching `src/link.ld`'s RAM at `0x80000000`), a
`<boards>` entry with `<mountedDevice>` pointing at it, and the example's required
`<board>` reference.

**Verification, done twice as carefully this time** (since `packchk`'s schema check had
already given a false pass once):
- `packchk.exe` → 0 errors, 2 benign warnings (M350 "no Startup component", expected for
  an example-only pack with no RTE components; M604 "no Dcore feature check for
  'other'", expected/intentional).
- **Independently validated against the actual `PACK.xsd` v1.7.7** using Python's `lxml`
  (no `xmllint` available locally) — `schema.validate(doc)` → `True`. This is the same
  gate CI's `xmllint --schema` step exercises; it's what should have been checked the
  first time instead of trusting `packchk` alone.

Docs corrected in `ec3942a` — the earlier "don't declare `<boards>` at all" advice in
`creating-a-cmsis-pack.md` was itself wrong and has been rewritten.

## 4. `pages` job: `CMSIS_PACK_ROOT` not set

**Symptom** (pages job, "Build pack" step):
```
gen_pack.sh> Warning: CMSIS_PACK_ROOT not set in environment.
gen_pack.sh> Error: CMSIS_PACK_ROOT pointing to /home/runner/.cache/arm/packs which
doesn't exist
Error: Process completed with exit code 1.
```

**Root cause:** the `build` job gets `CMSIS_PACK_ROOT` for free — `gen-pack-action` sets
the env var and creates `${CMSIS_PACK_ROOT}/.Web` itself before running the pack
script. The `pages` job calls `gen_pack.sh` directly (to rebuild the pack for the Pages
site) and never replicated that setup.

**Fix** (`be5822f`): in the `pages` job's "Build pack" step, before calling
`gen_pack.sh`:
```yaml
env:
  CMSIS_PACK_ROOT: /home/runner/.cache/arm/packs
run: |
  mkdir -p "${CMSIS_PACK_ROOT}"
  bash gen_pack.sh
```

## Summary table

| # | Symptom | Root cause | Fix commit |
|---|---------|------------|------------|
| 1 | exit 126 | `gen_pack.sh` missing execute bit | `d19fc8a` |
| 2 | Node 20 deprecation warning | stale action majors | `3786b16` |
| 3 | exit 1, xmllint schema failure | `<example>` missing required `<board>` | `a5bc25c` (+ docs `ec3942a`) |
| 4 | exit 1, pages job | `CMSIS_PACK_ROOT` unset/missing dir | `be5822f` |

## What to double-check before trusting the *next* green run

Nothing above was caught by a single tool alone — `packchk` missed #3 entirely, and each
fix so far has been validated against a *different* gate than the one that first
reported success. Before assuming a fresh pipeline run is fully clean, check that both
jobs (`build` and `pages`) show `conclusion: success` for *every* step — not just that
the top-level run didn't error — since a `needs:`-gated job can silently skip rather
than fail outright if an upstream condition isn't met.
