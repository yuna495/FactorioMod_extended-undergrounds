# Extended Undergrounds

Extended Undergrounds extends existing underground belts and pipe-to-ground entities in Factorio 2.0. It can also add darker deep variants that use a separate underground layer from the normal version.

The distance multiplier feature only changes distance fields on existing prototypes. The deep feature adds new entities, items, and recipes derived from compatible existing underground belts and pipe-to-ground prototypes.

## Settings

Configure these startup settings from Factorio's mod settings screen:

- Underground belt distance multiplier: default `2.0`, range `1.0` to `20.0`
- Underground pipe distance multiplier: default `5.0`, range `1.0` to `20.0`
- Add deep underground belts: default `true`
- Add deep underground pipes: default `true`

Startup settings are prototype-stage settings. After changing them, Factorio must reload prototypes by restarting or syncing/reloading mods before the new distances and generated prototypes take effect.

## Distance Calculation

Each distance is calculated from the original value already present on the normal prototype:

```text
new distance = min(255, max(1, floor(original distance x multiplier)))
```

Examples:

- Underground belt with `max_distance = 5` and multiplier `2.0` becomes `10`.
- Pipe connection with `max_underground_distance = 10` and multiplier `5.0` becomes `50`.
- Distance `20` with multiplier `20.0` would calculate to `400`, so it becomes `255`.
- Multiplier `1.0` keeps integer vanilla distances unchanged.

Distance multipliers are applied before deep variants are generated, so a normal prototype and its deep counterpart have the same distance.

## Deep Underground Variants

When enabled, this mod scans these prototype tables during `data-final-fixes.lua`:

- `data.raw["underground-belt"]`
- `data.raw["pipe-to-ground"]`

For each compatible normal prototype, it generates a new prototype named with the `extended-undergrounds-deep-` prefix, for example `extended-undergrounds-deep-underground-belt` or `extended-undergrounds-deep-pipe-to-ground`.

Generated deep underground belts are separate `underground-belt` prototypes. Factorio underground belts connect by compatible prototype type, so normal underground belts and deep underground belts do not connect to each other underground. This lets their underground paths overlap on the same straight line when their entrances and exits are placed on separate tiles.

Generated deep pipe-to-ground entities use a unique `connection_category` on underground pipe connections only. Normal ground pipe connections keep their original categories, so deep pipe-to-ground entities can still connect above ground to normal pipes and machines, while their underground connection only links to the matching deep prototype.

The mod does not place two entities on the same tile.

## Graphics

Deep variants reuse the original image files and add prototype tint only. The default tint is:

```lua
{r = 0.6, g = 0.6, b = 0.6, a = 1.0}
```

Tint is applied only to known sprite fields for underground belts and pipe-to-ground prototypes, plus item icons. Image files are not copied or edited.

## Compatibility With Other Mods

Prototype names are not hard-coded. Normal underground belts and pipe-to-ground prototypes added by other mods are handled when they use standard Factorio prototype fields.

An entity is only processed when this mod can find the item that places it by scanning `place_result`. If the item, source recipe, or a collision-free generated name cannot be determined safely, that prototype is skipped and a message is written to the Factorio log.

Deep recipes are based on the source recipe, preserve recipe category, crafting time, and existing ingredients, and add the corresponding normal item as an ingredient. If the source recipe is unlocked by technology, the deep recipe is unlocked by the same technology.

## Distance Limit

Factorio's prototype API defines these distance fields as `uint8`:

- `UndergroundBeltPrototype.max_distance`
- `PipeConnectionDefinition.max_underground_distance`

This mod clamps calculated distances to `1..255` and never writes a value above `255`.

## Load Order Notes

Distance changes and deep prototype generation run in `data-final-fixes.lua` so most other mods have already created their prototypes. If another mod changes the same distances or generated prototypes later in its own `data-final-fixes.lua`, the final value can depend on load order and may conflict.

No dependencies on specific third-party mods are declared.
