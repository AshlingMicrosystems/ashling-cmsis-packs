# Converting a CMake project into a hosted CMSIS-Pack

This walks through everything actually done to turn the plain-CMake
`QEMU32_RISCV_PicoJPEG` example into a validated, hosted, installable
[Open-CMSIS-Pack](https://open-cmsis-pack.github.io/Open-CMSIS-Pack-Spec/main/html/index.html),
in the order it was done. Use it as the template for adding the next pack to this repo.

## 0. Decide whether csolution.yml is even possible first

Before writing anything, check whether the target can be a real `csolution.yml`/
`cproject.yml` project (which is what lets it show up as a "CMSIS solution example" in
the CMSIS Solution VS Code extension's Create Solution picker), or whether it has to stay
a plain-environment pack example.

It comes down to two independent things, both verified directly against the installed
CMSIS-Toolbox rather than assumed:

- **Does CMSIS-Toolbox's build back-end support the target architecture?** Its bundled
  GCC toolchain file (`.../cmsis-toolbox/etc/GCC.10.3.1.cmake`) hard-codes the
  `arm-none-eabi-` compiler prefix and a fixed if/elseif chain over Arm `Dcore` names
  (Cortex-M0…M85, Cortex-A5/7/9), ending in `message(FATAL_ERROR "CPU is not
  supported!")` for anything else. If your target isn't an Arm Cortex-M/R/A core (ours
  is RV32IA), `cbuild` cannot build it — full stop, no workaround via a custom device
  or `Dcore="other"`.
- **Will it even show up in the picker if you fake it anyway?** The extension's own
  `dist/views/createSolution.js` only buckets examples whose `<environment>` toolchain
  is `csolution`/`cmsis` or `uv`. Everything else is silently dropped from the UI. So a
  non-Arm target gets neither the build nor the listing — there's no partial win.

If your target *is* Arm Cortex-M/R/A, a real `csolution.yml` project is the better,
more integrated choice and this guide doesn't apply — use the extension's own "Create
Solution" flow instead. If it isn't (RISC-V, Xtensa, a custom core, etc.), keep going:
the pack stays a plain-environment example (`<environment name="cmake" .../>` in our
case), and it will be installable/clonable but intentionally won't appear in Create
Solution's dropdown. Document that limitation up front so it isn't rediscovered later.

## 1. Make the CMake project buildable standalone

IDE integrations often inject CMake variables behind the scenes (compiler paths, extra
tool flags). A pack has to build for someone who *only* has the pdsc, the sources, and a
toolchain — no IDE magic. Audit `CMakeLists.txt` for anything referenced but never
defined in-repo, and either default it or guard the step that needs it:

```cmake
if(NOT DEFINED ExtraArchiveLibraries)
    set(ExtraArchiveLibraries "")
endif()
...
if(DEFINED ToolchainObjdump)
    add_custom_target(create-objdump ALL DEPENDS "${objdump}")
endif()
```

Verify with a from-scratch configure + build using only the documented command line
(no extension, no cached CMake variables):

```
cmake -G "Unix Makefiles" -S . -B build_verify \
  -DCMAKE_C_COMPILER=<toolchain>/riscv64-unknown-elf-gcc.exe \
  -DCMAKE_CXX_COMPILER=<toolchain>/riscv64-unknown-elf-g++.exe \
  -DCMAKE_ASM_COMPILER=<toolchain>/riscv64-unknown-elf-gcc.exe
cmake --build build_verify
```

## 2. Write the `.pdsc`

Structure for an example-only pack whose target has no real Open-CMSIS-Pack device
(e.g. non-Arm cores like our RV32IA):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<package schemaVersion="1.7.7" ...>
  <vendor>Ashling</vendor>
  <url>https://<final-hosting-url>/</url>
  <name>QEMU32_RISCV_PicoJPEG</name>
  <description>One line, under 128 chars, no embedded quotes/newlines.</description>
  <license>LICENSE.txt</license>
  <releases>
    <release version="1.0.0" date="YYYY-MM-DD">Initial release.</release>
  </releases>
  <keywords>...</keywords>

  <!-- Required even for a non-Arm target: the schema mandates <example><board>,
       which needs a real <boards> entry, which needs a <mountedDevice>, which
       needs a real <devices> entry to point at. Dcore="other" is the spec's own
       explicit value for this - it does NOT make the target buildable by
       CMSIS-Toolbox (see step 0); it only satisfies the metadata model. -->
  <devices>
    <family Dfamily="QEMU32_RISCV" Dvendor="Generic:5">
      <device Dname="QEMU32">
        <processor Dcore="other" DcoreVersion="RV32IA"/>
        <memory name="RAM" start="0x80000000" size="0x8000" access="rwx" default="1" startup="1"/>
      </device>
    </family>
  </devices>

  <boards>
    <board vendor="Generic" name="QEMU RISC-V virt">
      <description>One line.</description>
      <mountedDevice Dvendor="Generic:5" Dname="QEMU32"/>
    </board>
  </boards>

  <examples>
    <example name="picojpeg" doc="Abstract.txt" folder=".">
      <description>One line, under 128 chars.</description>
      <board vendor="Generic" name="QEMU RISC-V virt"/>
      <project>
        <environment name="cmake" load="CMakeLists.txt"/>
      </project>
      <attributes><category>Getting Started</category></attributes>
    </example>
  </examples>
</package>
```

Traps hit while building this, in the order they surface:

- **`<example>` requires a `<board>` child before `<project>` — this is enforced by the
  real `PACK.xsd`, not just `packchk`.** Skipping it (because there's no real device to
  mount) validates fine under `packchk`'s own bundled schema check, but fails CI's
  `xmllint --schema` step with `Element 'project': This element is not expected.
  Expected is (board)`. Don't try to dodge this by omitting `<boards>`/`<devices>`
  entirely — model a minimal device with `Dcore="other"` instead (as above). Verify
  against the *actual* XSD, not just `packchk`, before trusting a fix here — see step 3.
- **A declared `<boards><board>` needs a `<mountedDevice>`, or `packchk` errors (M375,
  "No mountedDevices for Board found").** This is what makes the `<devices>` block
  mandatory too, not just the `<board>` reference.
- **Keep `<description>` elements single-line and under ~128 chars.** Multi-line text
  trips `packchk`'s "unsupported character" warning (M388); anything over the limit
  trips the length warning (M387). Neither blocks a build, but a clean pack should have
  zero warnings.
- Expect two residual benign warnings with this minimal a device: **M350** ("No
  'Startup' component found") since there's no RTE component for it, and **M604**
  ("no Dcore feature check for 'other'") since it's intentionally not a real core. Both
  are informational, not errors.

## 3. Validate with `packchk`

Every CMSIS VS Code extension install ships `packchk` under
`<extension>/tools/cmsis-toolbox/bin/`. Use it before writing anything else:

```
packchk.exe Ashling.QEMU32_RISCV_PicoJPEG.pdsc
```

Target: **0 errors, 0 warnings** (or only the benign ones noted in step 2 for a
minimal/no-real-device pack). Iterate on the pdsc until you get there.

**`packchk`'s own "Xerxes schema check" passing is not proof the pdsc is schema-valid.**
It missed the missing-`<board>` issue above entirely (reported 0 errors both with and
without it) — only CI's separate `xmllint --schema <the-real-PACK.xsd>` step caught it.
If `xmllint` isn't available locally, validate with `lxml` instead before trusting a fix:

```python
from lxml import etree
schema = etree.XMLSchema(etree.parse("PACK.xsd"))   # fetch the version your pdsc declares
print(schema.validate(etree.parse("Vendor.Name.pdsc")))
for e in schema.error_log: print(e)
```

## 4. Package with `gen-pack`

Adopt the standard [Open-CMSIS-Pack/gen-pack](https://github.com/Open-CMSIS-Pack/gen-pack)
bash library — the same one used by essentially every official CMSIS-Pack repo. Copy its
`template/gen_pack.sh` into the pack folder and fill in:

```bash
REQUIRED_GEN_PACK_LIB="0.14.0"   # pin to a real tag from the gen-pack repo
PACK_DIRS="
  src
"
PACK_BASE_FILES="
  LICENSE.txt
  Abstract.txt
  CMakeLists.txt
  toolchain.cmake
"
```

This script, run with `bash gen_pack.sh`, re-runs `packchk` and produces
`output/<Vendor>.<Name>.<version>.pack` (a zip). It needs **Bash 5+** — Git-for-Windows'
bundled bash is often 4.x, so this step may only run for real in CI (that's fine; it's
exactly what CI is for).

Two more traps, both only surface in CI, not on this local dry-run:

- **`chmod +x gen_pack.sh` before committing it.** `gen-pack-action` invokes it directly
  as `./gen_pack.sh`, not `bash ./gen_pack.sh`. A file created by an editor/write-tool
  and never marked executable gets committed as git mode `100644`; on the Linux runner
  that fails with `Process completed with exit code 126` (permission denied). Fix:
  `git update-index --chmod=+x gen_pack.sh` (verify with `git ls-files -s gen_pack.sh` —
  should read `100755`), then commit.
- **`gen_pack.sh` needs `CMSIS_PACK_ROOT` set to an existing directory.** `gen-pack-action`
  sets this for you (default `/home/runner/.cache/arm/packs`), but if any *other* CI step
  calls `gen_pack.sh` directly (ours does, in the `pages` job — see step 6), it must
  `export CMSIS_PACK_ROOT=...` and `mkdir -p "$CMSIS_PACK_ROOT"` itself first, or the
  gen-pack library aborts with `Error: CMSIS_PACK_ROOT pointing to ... which doesn't exist`.

## 5. Decide the repo layout

If the repo is meant to hold exactly one pack forever, flat (files at repo root) is
simplest. If the repo name/intent implies more than one pack over time — like this one,
`ashling-cmsis-packs` — use a subfolder per pack from the start:

```
ashling-cmsis-packs/
├── README.md                          (index of packs)
├── .github/workflows/pack.yml
└── QEMU32_RISCV_PicoJPEG/
    ├── Ashling.QEMU32_RISCV_PicoJPEG.pdsc
    ├── gen_pack.sh
    ├── CMakeLists.txt / toolchain.cmake / Abstract.txt / LICENSE.txt / README.md
    └── src/
```

Moving files after the fact: use `git mv`, not delete+recreate, so history follows the
files.

## 6. CI/CD — GitHub Actions

Two jobs in `.github/workflows/pack.yml`:

- **`build`** (every push/PR/release/manual dispatch): checkout, then hand off to the
  official `Open-CMSIS-Pack/gen-pack-action`, pointed at the pack subfolder
  (`working-directory`). That action installs `packchk` and Python itself and runs
  `gen_pack.sh` — so this job is the CI equivalent of steps 3-4 above, running on a real
  Bash 5 environment. On a `release` event it also auto-attaches the built `.pack` to
  the release's downloadable assets.
- **`pages`** (push to `main` or manual dispatch only): checkout again, install
  `packchk` directly (curl the Linux release from the CMSIS-Toolbox GitHub releases),
  export `CMSIS_PACK_ROOT` and `mkdir -p` it (see the two traps at the end of step 4 —
  this job calls `gen_pack.sh` directly, so nothing sets this up for free), rebuild with
  `gen_pack.sh`, then assemble a `public/<pack>/` folder containing the `.pdsc`, the
  `.pack`, and a generated `index.pidx` pack index (see step 8), and deploy it via
  `actions/upload-pages-artifact` + `actions/deploy-pages`.

The `index.pidx` is generated inline in the workflow (not by `gen-pack-action`, which
only handles docs/pack build, not pack-index publishing):

```bash
PACK_VERSION=$(xmlstarlet sel -t -v "//releases/release[1]/@version" "$PDSC")
cat > "$SITE/index.pidx" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<index schemaVersion="1.1.1" ...>
  <vendor>Ashling</vendor>
  <url>https://<pages-url>/</url>
  <timestamp>$(date -u +%Y-%m-%dT%H:%M:%S)</timestamp>
  <pindex>
    <pdsc url="https://<pages-url>/" vendor="Ashling" name="QEMU32_RISCV_PicoJPEG" version="${PACK_VERSION}"/>
  </pindex>
</index>
EOF
```

Point the pdsc's own `<url>` element at that same Pages URL — that's where `cpackget`
downloads the `.pack` from once someone's added your `.pidx`.

## 7. One-time GitHub repo settings (can't be done via git push)

- **Settings → Pages → Build and deployment → Source → "GitHub Actions"** — without
  this the `pages` job's `deploy-pages` step has nothing to deploy to.
- **Settings → Actions → General → Actions permissions → "Allow all actions and
  reusable workflows"** (or explicitly allow `Open-CMSIS-Pack/gen-pack-action`,
  `actions/upload-pages-artifact`, `actions/deploy-pages`) — third-party actions are
  blocked by default under the stricter "GitHub actions only" setting some orgs use.
- **Repo visibility matters for Pages**: public repos get Pages free on any plan;
  private repos need the org on GitHub Team/Enterprise. If Pages isn't available,
  drop the `pages` job and rely on the `build` job's release-asset attachment instead —
  users then `cpackget add` a specific release's `.pack` URL rather than a `.pidx`.

## 8. Push

```
git init                       # if not already a repo
git add -A && git commit -m "..."
git remote add origin https://github.com/<org>/<repo>.git
git push -u origin main
```

Pushing to a shared/public remote is a one-way, visible action — confirm the remote URL
and branch name before running the push, especially the first time.

## 9. Publish / install

Once the `pages` job has run at least once on `main`:

```
cpackget add https://<org>.github.io/<repo>/<pack>/index.pidx
```

For local development before anything is pushed, skip hosting entirely and install
straight from the working copy:

```
cpackget add <pack-folder>/Ashling.QEMU32_RISCV_PicoJPEG.pdsc
cpackget list          # confirm it shows up as Vendor::Name@version
```

To make the pack discoverable to *other people's* browse/search UI without them running
`cpackget add` themselves, the pdsc/pidx URL needs to be submitted to Arm's public index
(`CMSIS@arm.com`) — a manual, external step, not a repo setting.

## 10. What "testing with CMSIS tools" actually means here

- `packchk` / `cpackget` (both bundled with the CMSIS VS Code extension under
  `tools/cmsis-toolbox/bin/`) are the real validation and install-testing tools — use
  them exactly as in steps 3 and 9.
- The CMSIS Solution extension's **Manage Components and Packs** view should show the
  pack once it's installed via `cpackget` (same pack root).
- The **Create Solution** dropdown will not show this example — that's expected per
  step 0, not a bug to chase.
- Actually building/running the firmware happens outside the CMSIS extension entirely:
  plain `cmake --build` plus (for this project) the existing `.vscode/launch.json`
  QEMU/GDB debug config, or the `qemu-system-riscv32 -kernel ...` command from the
  pack's own README.
