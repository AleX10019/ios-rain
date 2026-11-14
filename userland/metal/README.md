# Metal driver (from HakiOS)

Taken unchanged from HakiOS userland (`github.com/oosexgang/hackios-xnu-userland`, commit
`a79ff0772a3454fd1ef127e181e5b3bce6c9ce18`, MIT, see `HAKIOS-LICENSE.txt`); the AIR shader
frontend it needs is in `../mesa/air` with the Mesa patches `../mesa/air-*.patch` and
`../mesa/ir3-*.patch`. Plan: `docs/METAL-rain.md`.

- `redwoodmetal.m` + `redwooddrawable.m`: the Metal device (`RedwoodMetal.bundle`, class
  `RedwoodMetalDevice`), on Mesa freedreno through `../mesa/redwood-drm` and the kernel's `RedwoodGPU`.
- `metal_drv_test.m`: walks Metal's discovery against the bundle and runs small jobs.
- `metal_props.c`: sets/clears MetalPluginName/MetalPluginClassName on IOAcceleratorES.

The sources load `/redwood/lib/libredwoodair.dylib` and `/redwood/lib/RedwoodMetal.bundle`, so on
rain those live in `/redwood/lib` (not `/topaz/lib`).
