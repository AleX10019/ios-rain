# Metal on rain: research and plan

Written 2026-11-14. Nothing here has run on the phone yet.

## Where Metal can come from

- **HakiOS userland** (`github.com/oosexgang/hackios-xnu-userland`, MIT), the family our userland
  comes from. ios-sweet pins commit `a79ff0772a3454fd1ef127e181e5b3bce6c9ce18` as its donor:
  - `tools/mesa/air/`: an AIR (Metal IR) frontend for Mesa, about 20k lines (`air_module.c`,
    `air_to_nir.c`, `air_metal.c`, `air_run.c`, ...), plus six Mesa patches (`air-frontend`,
    `air-ir3`, `air-metal`, three ir3 fixes).
  - `userland/src/redwoodmetal.m` (6.3k lines): the Metal driver (device, queues, buffers, textures,
    pipelines, encoders) on top of Mesa/freedreno, and `redwooddrawable.m` for CAMetalLayer.
  - `metal_plugin.plist`, `metal_props.c`: the bundle and the switch that makes Metal find it.
  - Its own corpus report: 321 of 456 shader modules of the system's Metal libraries compile through ir3.
- **ios-sweet** (`userspace/native-metal`) runs that donor on an Adreno 618 with its own kernel
  transport ("NativeAdreno ABI1"). We do not need that part.

## Why it fits rain

| | ours | donor |
| --- | --- | --- |
| Mesa | 25.0.7, sha256 592272df... | 25.0.7, same archive |
| DRM transport (`redwood-drm/`) | `redwood_drm.c`, `xf86drm.h` | byte-for-byte identical |
| `freedreno-darwin.patch` | | 2 lines differ |
| Kernel GPU service | `RedwoodGPU` (iokit/Kernel/arm/RedwoodGPU.cpp) | `RedwoodGPU` |
| Direct kernel calls of `redwoodmetal.m` | GEM_NEW, GEM_INFO, GEM_CLOSE, GET_PARAM (0x40): all used by our GL path already | |
| GPU | Adreno 610 (a6xx) | written for the POCO X5 Pro (Adreno 642L, a6xx); freedreno drives both |

## How Metal finds a GPU (donor docs/metal.md)

`MTLRegisterDevices()` enumerates `IOServiceMatching("IOAcceleratorES")`, reads `MetalPluginName`
and `MetalPluginClassName` from the service, opens `/System/Library/Extensions/<name>.bundle` and
instantiates the class. Our framebuffer publishes an empty `IOAcceleratorES` ("sgx") on purpose
without those properties (SweetFramebuffer.cpp), so nothing uses Metal today.

## Plan

1. **Userland CI**: add the donor's `tools/mesa/air` and its Mesa patches to `userland/mesa`; build
   Mesa with the AIR frontend; build `RedwoodMetal.bundle` from `redwoodmetal.m` (+ drawable) and a
   test program (`metal_drv_test`, triangle app). Several CI rounds on macOS.
2. **Kernel**: boot-arg `metal=1` puts `MetalPluginName=RedwoodMetal`,
   `MetalPluginClassName=RedwoodMetalDevice` on the IOAcceleratorES service.
3. **Root image**: install the bundle at `/System/Library/Extensions/RedwoodMetal.bundle` and the
   test programs (one userdata reflash).
4. **Phone**: `metal_drv_test` (device found, buffers, a clear), then the triangle app, then
   AegirPoster / CollectionsPoster and SpringBoard.

Risks: A610-specific limits (GMEM size, formats) the donor never met on the 642L; the IOSurface
glue (our SweetSurface vs the donor's kernel); 30 % of the system's shaders do not translate yet.
Estimate: a first triangle in 1-2 days of work, system use (wallpapers, Safari paths) several more.
