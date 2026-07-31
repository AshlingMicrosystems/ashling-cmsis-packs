# ashling-cmsis-packs

[Open-CMSIS-Pack](https://open-cmsis-pack.github.io/Open-CMSIS-Pack-Spec/main/html/index.html)
packages published by Ashling Microsystems. Each subfolder is one independent pack with
its own `.pdsc`, source, and packaging script.

| Pack | Description |
|------|--------------|
| [QEMU32_RISCV_PicoJPEG](QEMU32_RISCV_PicoJPEG/) | Bare-metal RV32IA picojpeg JPEG-decode example, built with CMake, run under QEMU's "virt" machine model. |

## Installing a pack

```
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/<pack>/<Vendor>.<Pack>.<version>.pack
```

(`-a` auto-accepts the pack's embedded license non-interactively; omit it to be
prompted instead.) Each pack's own README has its exact URL. `index.pidx` is also
published alongside each pack for tooling that consumes pack indexes directly — but
`cpackget add` itself only takes a pack id, a `.pack` file/URL, or a local `.pdsc` path,
not a `.pidx` URL.

## Adding a new pack to this repository

1. Create a new top-level folder named after the pack.
2. Add its `.pdsc`, sources, `LICENSE`, and a `gen_pack.sh` (copy an existing pack's as a
   starting point — see [gen-pack](https://github.com/Open-CMSIS-Pack/gen-pack)).
3. Add a matching job/step in `.github/workflows/pack.yml`.

See [docs/creating-a-cmsis-pack.md](docs/creating-a-cmsis-pack.md) for the full
walkthrough (converting a CMake project, validating, packaging, CI, hosting, and
testing), using `QEMU32_RISCV_PicoJPEG` as the worked example, and
[docs/ci-pipeline-fixes.md](docs/ci-pipeline-fixes.md) for the incident-by-incident log
of every CI failure hit while getting that pack's pipeline green.
