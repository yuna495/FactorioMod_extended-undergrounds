data:extend({
  {
    type = "double-setting",
    name = "extended-undergrounds-belt-distance-multiplier",
    setting_type = "startup",
    minimum_value = 1.0,
    maximum_value = 20.0,
    default_value = 2.0,
    order = "a[underground-belt-distance-multiplier]"
  },
  {
    type = "double-setting",
    name = "extended-undergrounds-pipe-distance-multiplier",
    setting_type = "startup",
    minimum_value = 1.0,
    maximum_value = 20.0,
    default_value = 5.0,
    order = "b[underground-pipe-distance-multiplier]"
  },
  {
    type = "bool-setting",
    name = "extended-undergrounds-add-deep-underground-belts",
    setting_type = "startup",
    default_value = true,
    order = "c[deep-underground-belts]"
  },
  {
    type = "bool-setting",
    name = "extended-undergrounds-add-deep-pipe-to-ground",
    setting_type = "startup",
    default_value = true,
    order = "d[deep-pipe-to-ground]"
  }
})
