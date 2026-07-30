# References

This mod was created as original code. It does not copy source code from the referenced mod below.

## Longer underground pipes

- Internal name: `longer-pipe-to-ground`
- Version inspected: `1.0.4`
- Author / Mod Portal owner: SomethingwithS
- Mod Portal: https://mods.factorio.com/mod/longer-pipe-to-ground
- License listed on Mod Portal: MIT

The referenced mod showed a simple approach for changing pipe-to-ground underground distance on existing prototypes. Extended Undergrounds uses its own implementation: it scans all `pipe-to-ground` prototypes during `data-final-fixes.lua` and applies a startup multiplier to every pipe connection that already has `max_underground_distance`.
