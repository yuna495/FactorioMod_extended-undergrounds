local MIN_UNDERGROUND_DISTANCE = 1
local MAX_UNDERGROUND_DISTANCE = 255

local function scaled_underground_distance(original_distance, multiplier)
  local distance = math.floor(original_distance * multiplier)

  if distance < MIN_UNDERGROUND_DISTANCE then
    return MIN_UNDERGROUND_DISTANCE
  end

  if distance > MAX_UNDERGROUND_DISTANCE then
    return MAX_UNDERGROUND_DISTANCE
  end

  return distance
end

local function startup_setting_value(name)
  local startup_settings = settings and settings.startup or {}
  local setting = startup_settings[name]
  if setting and type(setting.value) == "number" then
    return setting.value
  end

  return 1.0
end

local belt_multiplier = startup_setting_value("extended-undergrounds-belt-distance-multiplier")
local pipe_multiplier = startup_setting_value("extended-undergrounds-pipe-distance-multiplier")

for _, underground_belt in pairs(data.raw["underground-belt"] or {}) do
  if type(underground_belt) == "table" and type(underground_belt.max_distance) == "number" then
    underground_belt.max_distance = scaled_underground_distance(underground_belt.max_distance, belt_multiplier)
  end
end

for _, pipe_to_ground in pairs(data.raw["pipe-to-ground"] or {}) do
  local fluid_box = type(pipe_to_ground) == "table" and pipe_to_ground.fluid_box or nil

  if type(fluid_box) == "table" and type(fluid_box.pipe_connections) == "table" then
    for _, pipe_connection in pairs(fluid_box.pipe_connections) do
      if type(pipe_connection) == "table" and type(pipe_connection.max_underground_distance) == "number" then
        pipe_connection.max_underground_distance = scaled_underground_distance(
          pipe_connection.max_underground_distance,
          pipe_multiplier
        )
      end
    end
  end
end
