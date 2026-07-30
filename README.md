# ashling-cmsis-packs

[Open-CMSIS-Pack](https://open-cmsis-pack.github.io/Open-CMSIS-Pack-Spec/main/html/index.html)
packages published by Ashling Microsystems. Each subfolder is one independent pack with
its own `.pdsc`, source, and packaging script.

| Pack | Description |
|------|--------------|
| [QEMU32_RISCV_PicoJPEG](QEMU32_RISCV_PicoJPEG/) | Bare-metal RV32IA picojpeg JPEG-decode example, built with CMake, run under QEMU's "virt" machine model. |

## Installing a pack

```
cpackget add https://ashlingmicrosystems.github.io/ashling-cmsis-packs/<pack>/index.pidx
```

or point `cpackget add` directly at a released `.pack` file.

## Adding a new pack to this repository

1. Create a new top-level folder named after the pack.
2. Add its `.pdsc`, sources, `LICENSE`, and a `gen_pack.sh` (copy an existing pack's as a
   starting point — see [gen-pack](https://github.com/Open-CMSIS-Pack/gen-pack)).
3. Add a matching job/step in `.github/workflows/pack.yml`.

See [docs/creating-a-cmsis-pack.md](docs/creating-a-cmsis-pack.md) for the full
walkthrough (converting a CMake project, validating, packaging, CI, hosting, and
testing), using `QEMU32_RISCV_PicoJPEG` as the worked example.
