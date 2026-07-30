# Extended Undergrounds

Extended Undergrounds extends the connection distance of existing underground belts and pipe-to-ground entities in Factorio 2.0.

It does not add new items, entities, recipes, or technologies. It only changes distance fields on existing prototypes during `data-final-fixes.lua`.

## Settings

Configure these startup settings from Factorio's mod settings screen:

- Underground belt distance multiplier: default `3.0`, range `1.0` to `20.0`
- Underground pipe distance multiplier: default `3.0`, range `1.0` to `20.0`

Startup settings are prototype-stage settings. After changing them, Factorio must reload prototypes by restarting or syncing/reloading mods before the new distances take effect.

## Distance Calculation

Each distance is calculated from the original value already present on the prototype:

```text
new distance = min(255, max(1, floor(original distance x multiplier)))
```

Examples:

- Underground belt with `max_distance = 5` and multiplier `3.0` becomes `15`.
- Pipe connection with `max_underground_distance = 10` and multiplier `2.0` becomes `20`.
- Distance `20` with multiplier `20.0` would calculate to `400`, so it becomes `255`.
- Multiplier `1.0` keeps integer vanilla distances unchanged.

## Compatibility With Other Mods

During `data-final-fixes.lua`, this mod scans all prototypes in:

- `data.raw["underground-belt"]`
- `data.raw["pipe-to-ground"]`

Prototype names are not hard-coded, so normal underground belts and pipe-to-ground prototypes added by other mods are handled automatically when they expose the standard distance fields.

For underground belts, only `max_distance` is changed. Belt speed, graphics, icons, items, recipes, and technologies are not changed.

For pipe-to-ground prototypes, every `fluid_box.pipe_connections` entry that has `max_underground_distance` is changed. Pipe recipes, graphics, icons, and fluid throughput fields are not changed.

## Distance Limit

Factorio's prototype API defines these distance fields as `uint8`:

- `UndergroundBeltPrototype.max_distance`
- `PipeConnectionDefinition.max_underground_distance`

This mod clamps calculated distances to `1..255` and never writes a value above `255`.

## Load Order Notes

Distance changes run in `data-final-fixes.lua` so most other mods have already created their prototypes. If another mod changes the same distances later in its own `data-final-fixes.lua`, the final value can depend on load order and may conflict.

No dependencies on specific third-party mods are declared.
