# References

This mod was created as original code. It does not copy source code from the referenced mods below.

## Longer underground pipes

- Internal name: `longer-pipe-to-ground`
- Version inspected: `1.0.4`
- Author / Mod Portal owner: SomethingwithS
- Mod Portal: https://mods.factorio.com/mod/longer-pipe-to-ground
- License listed on Mod Portal: MIT

The referenced mod showed a simple approach for changing pipe-to-ground underground distance on existing prototypes. Extended Undergrounds uses its own implementation: it scans all `pipe-to-ground` prototypes during `data-final-fixes.lua` and applies a startup multiplier to every pipe connection that already has `max_underground_distance`.

## Deep underground belt 2

- Repository inspected: https://github.com/Rugal/deep-underground-belt
- Version inspected: repository `master` at `7e9af434ad1ef593d33ac9ba898dc9f5ed20148d`
- Authors listed in `info.json`: w1102, Rugal Bernstein
- Mod Portal listed in `info.json`: https://mods.factorio.com/mod/deep-underground-belt-2

The referenced mod confirmed the gameplay approach of separating underground belts by creating distinct underground-belt prototypes. Extended Undergrounds implements its own Factorio 2.0 data-stage generator and does not copy its source code or image assets.
