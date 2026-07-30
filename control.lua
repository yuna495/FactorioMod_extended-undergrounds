local WAIT_TICKS = 12
local YELLOW_SPRITE = "extended-undergrounds-distance-marker-yellow"
local GREEN_SPRITE = "extended-undergrounds-distance-marker-green"
local MARKER_SCALE = 0.5

local function ensure_storage()
  storage.players = storage.players or {}
  storage.waiting_players = storage.waiting_players or {}
end

local function state_for_player(player_index)
  ensure_storage()
  local state = storage.players[player_index]
  if not state then
    state = {renders = {}}
    storage.players[player_index] = state
  end
  state.renders = state.renders or {}
  return state
end

local function destroy_renders(state)
  if not state or type(state.renders) ~= "table" then
    return
  end

  for _, render_object in pairs(state.renders) do
    if render_object and render_object.valid then
      render_object.destroy()
    end
  end

  state.renders = {}
  state.shown_unit_number = nil
  state.shown_surface_index = nil
end

local function reset_wait(player_index, state)
  storage.waiting_players[player_index] = nil
  if state then
    state.waiting_unit_number = nil
    state.waiting_surface_index = nil
    state.waiting_entity = nil
    state.wait_started_tick = nil
  end
end

local function clear_player_state(player_index)
  local state = state_for_player(player_index)
  destroy_renders(state)
  reset_wait(player_index, state)
end

local function direction_vector(direction)
  if direction == defines.direction.east then
    return 1, 0
  elseif direction == defines.direction.south then
    return 0, 1
  elseif direction == defines.direction.west then
    return -1, 0
  end

  return 0, -1
end

local function marker_distances(max_distance)
  local distances = {}
  local step = 10

  while step < max_distance do
    table.insert(distances, {distance = step, sprite = YELLOW_SPRITE})
    step = step + 10
  end

  table.insert(distances, {distance = max_distance, sprite = GREEN_SPRITE})
  return distances
end

local function entity_marker_kind(entity)
  if not entity or not entity.valid then
    return nil
  end

  if entity.type == "underground-belt" then
    return "belt"
  elseif entity.type == "pipe-to-ground" then
    return "pipe"
  end

  return nil
end

local function marker_distance_from_entity(entity)
  if not entity or not entity.valid or not entity.prototype then
    return nil
  end

  local distance = entity.prototype.max_underground_distance
  if type(distance) ~= "number" or distance < 1 then
    return nil
  end

  return math.floor(distance)
end

local function is_marker_target(entity)
  return entity_marker_kind(entity) ~= nil and marker_distance_from_entity(entity) ~= nil
end

local function draw_marker_sprite(player_index, entity, sprite, offset)
  return rendering.draw_sprite{
    sprite = sprite,
    target = {type = "entity", entity = entity, offset = offset},
    surface = entity.surface,
    x_scale = MARKER_SCALE,
    y_scale = MARKER_SCALE,
    render_layer = "arrow",
    players = {player_index},
    only_in_alt_mode = false
  }
end

local function draw_belt_markers(player_index, entity, distance, renders)
  local dx, dy = direction_vector(entity.direction)

  for _, marker in pairs(marker_distances(distance)) do
    local distance_dx = dx * marker.distance
    local distance_dy = dy * marker.distance
    table.insert(renders, draw_marker_sprite(player_index, entity, marker.sprite, {distance_dx, distance_dy}))
    table.insert(renders, draw_marker_sprite(player_index, entity, marker.sprite, {-distance_dx, -distance_dy}))
  end
end

local function draw_pipe_markers(player_index, entity, distance, renders)
  for _, marker in pairs(marker_distances(distance)) do
    local d = marker.distance
    table.insert(renders, draw_marker_sprite(player_index, entity, marker.sprite, {0, -d}))
    table.insert(renders, draw_marker_sprite(player_index, entity, marker.sprite, {d, 0}))
    table.insert(renders, draw_marker_sprite(player_index, entity, marker.sprite, {0, d}))
    table.insert(renders, draw_marker_sprite(player_index, entity, marker.sprite, {-d, 0}))
  end
end

local function show_markers(player_index, entity, state)
  destroy_renders(state)

  local distance = marker_distance_from_entity(entity)
  local kind = entity_marker_kind(entity)
  if not distance or not kind then
    return
  end

  local renders = {}
  if kind == "belt" then
    draw_belt_markers(player_index, entity, distance, renders)
  else
    draw_pipe_markers(player_index, entity, distance, renders)
  end

  state.renders = renders
  state.shown_unit_number = entity.unit_number
  state.shown_surface_index = entity.surface.index
end

local function begin_waiting(player_index, entity, tick)
  local state = state_for_player(player_index)
  destroy_renders(state)

  if not is_marker_target(entity) then
    reset_wait(player_index, state)
    return
  end

  state.waiting_entity = entity
  state.waiting_unit_number = entity.unit_number
  state.waiting_surface_index = entity.surface.index
  state.wait_started_tick = tick
  storage.waiting_players[player_index] = true
end

local function current_selection_is_wait_target(player, state)
  local selected = player.selected
  return selected and selected.valid and
    state.waiting_entity and state.waiting_entity.valid and
    selected == state.waiting_entity and
    selected.unit_number == state.waiting_unit_number and
    selected.surface.index == state.waiting_surface_index and
    player.surface.index == state.waiting_surface_index
end

script.on_init(function()
  ensure_storage()
end)

script.on_configuration_changed(function()
  if rendering and rendering.clear then
    rendering.clear("extended-undergrounds")
  end
  storage.players = {}
  storage.waiting_players = {}
end)

script.on_event(defines.events.on_selected_entity_changed, function(event)
  local player = game.get_player(event.player_index)
  if not player or not player.valid then
    clear_player_state(event.player_index)
    return
  end

  begin_waiting(event.player_index, player.selected, event.tick)
end)

script.on_event(defines.events.on_tick, function(event)
  ensure_storage()

  for player_index in pairs(storage.waiting_players) do
    local player = game.get_player(player_index)
    local state = storage.players[player_index]

    if not player or not player.valid or not state or not current_selection_is_wait_target(player, state) then
      clear_player_state(player_index)
    elseif event.tick - state.wait_started_tick >= WAIT_TICKS then
      show_markers(player_index, state.waiting_entity, state)
      reset_wait(player_index, state)
    end
  end
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
  clear_player_state(event.player_index)
end)

script.on_event(defines.events.on_pre_player_left_game, function(event)
  clear_player_state(event.player_index)
end)

script.on_event(defines.events.on_player_removed, function(event)
  clear_player_state(event.player_index)
  storage.players[event.player_index] = nil
end)