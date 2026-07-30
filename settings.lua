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
  }
})
