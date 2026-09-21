# ashling-cmsis-packs

[Open-CMSIS-Pack](https://open-cmsis-pack.github.io/Open-CMSIS-Pack-Spec/main/html/index.html)
packages published by Ashling Microsystems. Each subfolder is one independent pack with
its own `.pdsc`, source, and packaging script, organized in three tiers so example packs
don't redeclare devices/boards from scratch:

| Pack | Tier | Description |
|------|------|-------------|
| [SiFive_E_DFP](SiFive_E_DFP/) | Device Family Pack | SiFive E-Series RISC-V cores (E31, E51, FE310) + xsvd peripheral register files. |
| [QEMU_RISCV_DFP](QEMU_RISCV_DFP/) | Device Family Pack | QEMU's RISC-V virtual machine target (QEMU32) + its xsvd file. |
| [ArtyA7-100T_BSP](ArtyA7-100T_BSP/) | Board Support Pack | Digilent Arty A7-100T board (SiFive E31 core). Requires `SiFive_E_DFP`. |
| [QEMU_RISCV_BSP](QEMU_RISCV_BSP/) | Board Support Pack | QEMU's "virt" machine model as a virtual board. Requires `QEMU_RISCV_DFP`. |
| [PicoJPEG](PicoJPEG/) | Generic Software Pack (example) | Bare-metal RV32IA picojpeg JPEG-decode example, built with CMake. Ships two variants (`qemu/`, `arty/`) targeting the two BSPs above. |

Future example packs (e.g. a FreeRTOS sample) follow the same pattern: a new GSP pack
requiring the existing DFP/BSP packs, not new device/board declarations.

## Installing packs

Either add packs individually:

```
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/<pack>/<Vendor>.<Pack>.<version>.pack
```

(`-a` auto-accepts the pack's embedded license non-interactively; omit it to be
prompted instead.) `PicoJPEG` depends on the four DFP/BSP packs above, so install those
first. Each pack's own README has its exact URL.

Or point `cpackget` at the combined root index, which lists every pack in this repo:

```
cpackget index https://ashlingmicrosystems.github.io/ashling-cmsis-packs/index.pidx
```

**Caveat:** `cpackget`/`CMSIS_PACK_ROOT` tracks only one active index at a time — this
*replaces* whatever index was active (typically the default public Keil/Arm one), so
short-form lookups like `cpackget add Vendor.OtherPack` for other vendors' packs stop
resolving until you point the index back (`cpackget index https://www.keil.com/pack/index.pidx`).
It's also not confirmed whether the CMSIS Solution VS Code extension's "Create Solution"
picker browses packs from a configured index that aren't installed yet, or only shows
already-installed ones — test directly if that matters for your workflow.

`cpackget add` itself only takes a pack id, a `.pack` file/URL, or a local `.pdsc` path,
not a `.pidx` URL — the index is only useful for `cpackget index`/short-form `add`
resolution, not as a direct argument to `add`.

## Adding a new pack to this repository

1. Create a new top-level folder named after the pack.
2. Add its `.pdsc`, sources, `LICENSE`, and a `gen_pack.sh` (copy an existing pack's as a
   starting point — see [gen-pack](https://github.com/Open-CMSIS-Pack/gen-pack)). If it's
   an example (GSP) pack, declare `<requirements><packages>` on whichever DFP/BSP packs
   it targets rather than declaring its own `<devices>`/`<boards>`.
3. Add it to the dependency-ordered pack list in `.github/workflows/pack.yml` (the
   `for pack in ...` loops in both the "Build and validate" and "Assemble combined pack
   index site" steps) — DFPs first, then BSPs, then GSP/example packs, so
   `<requirements><packages>` can resolve via packchk. This repo builds and deploys all
   packs together in one job (not one workflow per pack) specifically so every pack's
   `.pack`/`.pdsc` stays live on GitHub Pages at once, alongside the combined
   `index.pidx`.

See [docs/creating-a-cmsis-pack.md](docs/creating-a-cmsis-pack.md) for the full
walkthrough (converting a CMake project, validating, packaging, CI, hosting, and
testing) and [docs/ci-pipeline-fixes.md](docs/ci-pipeline-fixes.md) for the
incident-by-incident log of every CI failure hit while getting the original single-pack
pipeline green. Both predate the DFP/BSP/GSP split — useful for the packaging/`packchk`
mechanics, but their repo-layout details describe the earlier, single-pack structure.
