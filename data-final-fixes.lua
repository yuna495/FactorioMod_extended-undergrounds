local MIN_UNDERGROUND_DISTANCE = 1
local MAX_UNDERGROUND_DISTANCE = 255
local DEEP_PREFIX = "extended-undergrounds-deep-"
local DEEP_TINT = {r = 0.6, g = 0.6, b = 0.6, a = 1.0}

local function deepcopy(value)
  local copier = table.deepcopy or (util and util.table and util.table.deepcopy)
  if copier then
    return copier(value)
  end

  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, child in pairs(value) do
    copy[deepcopy(key)] = deepcopy(child)
  end
  return copy
end

local function write_log(message)
  if log then
    log("[Extended Undergrounds] " .. message)
  end
end

local function is_deep_name(name)
  return type(name) == "string" and name:sub(1, #DEEP_PREFIX) == DEEP_PREFIX
end

local function deep_name_for(source_name)
  return DEEP_PREFIX .. source_name
end

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

local function startup_setting_value(name, default_value)
  local startup_settings = settings and settings.startup or {}
  local setting = startup_settings[name]
  if setting and type(setting.value) == type(default_value) then
    return setting.value
  end

  return default_value
end

local function prototype_exists(prototype_type, name)
  return data.raw[prototype_type] and data.raw[prototype_type][name] ~= nil
end

local function multiplied_tint(existing_tint)
  if type(existing_tint) ~= "table" then
    return deepcopy(DEEP_TINT)
  end

  local r = existing_tint.r or existing_tint[1] or 1
  local g = existing_tint.g or existing_tint[2] or 1
  local b = existing_tint.b or existing_tint[3] or 1
  local a = existing_tint.a or existing_tint[4] or 1

  return {
    r = math.min(1, math.max(0, r * DEEP_TINT.r)),
    g = math.min(1, math.max(0, g * DEEP_TINT.g)),
    b = math.min(1, math.max(0, b * DEEP_TINT.b)),
    a = a
  }
end

local function tint_sprite(sprite)
  if type(sprite) ~= "table" then
    return
  end

  if type(sprite.layers) == "table" then
    for _, layer in pairs(sprite.layers) do
      tint_sprite(layer)
    end
    return
  end

  if type(sprite.sheet) == "table" then
    tint_sprite(sprite.sheet)
  end

  if type(sprite.sheets) == "table" then
    for _, sheet in pairs(sprite.sheets) do
      tint_sprite(sheet)
    end
  end

  if type(sprite.hr_version) == "table" then
    tint_sprite(sprite.hr_version)
  end

  if sprite.filename or sprite.filenames or sprite.stripes then
    sprite.tint = multiplied_tint(sprite.tint)
  end
end

local function tint_sprite_4_way(sprite_4_way)
  if type(sprite_4_way) ~= "table" then
    return
  end

  local has_directional_sprite = false
  for _, direction in pairs({"north", "east", "south", "west"}) do
    if type(sprite_4_way[direction]) == "table" then
      has_directional_sprite = true
      tint_sprite(sprite_4_way[direction])
    end
  end

  if not has_directional_sprite then
    tint_sprite(sprite_4_way)
  end
end

local function tint_underground_belt_graphics(underground_belt)
  if type(underground_belt.structure) == "table" then
    for _, key in pairs({
      "direction_in",
      "direction_out",
      "direction_in_side_loading",
      "direction_out_side_loading",
      "back_patch",
      "front_patch",
      "frozen_patch_in",
      "frozen_patch_out"
    }) do
      tint_sprite_4_way(underground_belt.structure[key])
    end
  end

  tint_sprite(underground_belt.underground_sprite)
  tint_sprite(underground_belt.underground_remove_belts_sprite)
  tint_sprite(underground_belt.max_distance_underground_remove_belts_sprite)
end

local function tint_pipe_to_ground_graphics(pipe_to_ground)
  tint_sprite_4_way(pipe_to_ground.pictures)
  tint_sprite_4_way(pipe_to_ground.frozen_patch)
  tint_sprite_4_way(pipe_to_ground.visualization)
  tint_sprite_4_way(pipe_to_ground.disabled_visualization)
end

local function tinted_icons_from(source)
  if type(source.icons) == "table" then
    local icons = deepcopy(source.icons)
    for _, icon_data in pairs(icons) do
      if type(icon_data) == "table" then
        icon_data.tint = multiplied_tint(icon_data.tint)
      end
    end
    return icons
  end

  if source.icon then
    return {{
      icon = source.icon,
      icon_size = source.icon_size or 64,
      icon_mipmaps = source.icon_mipmaps,
      tint = deepcopy(DEEP_TINT)
    }}
  end

  return nil
end

local function apply_tinted_icons(target, source)
  local icons = tinted_icons_from(source)
  if icons then
    target.icons = icons
    target.icon = nil
    target.icon_size = nil
    target.icon_mipmaps = nil
  end

  if type(source.dark_background_icons) == "table" then
    target.dark_background_icons = deepcopy(source.dark_background_icons)
    for _, icon_data in pairs(target.dark_background_icons) do
      if type(icon_data) == "table" then
        icon_data.tint = multiplied_tint(icon_data.tint)
      end
    end
    target.dark_background_icon = nil
    target.dark_background_icon_size = nil
    target.dark_background_icon_mipmaps = nil
  elseif source.dark_background_icon then
    target.dark_background_icons = {{
      icon = source.dark_background_icon,
      icon_size = source.dark_background_icon_size or 64,
      icon_mipmaps = source.dark_background_icon_mipmaps,
      tint = deepcopy(DEEP_TINT)
    }}
    target.dark_background_icon = nil
    target.dark_background_icon_size = nil
    target.dark_background_icon_mipmaps = nil
  end
end

local function deep_localised_name(source, locale_prefix)
  local base_name = source.localised_name or {locale_prefix .. "-name." .. source.name}
  return {"extended-undergrounds.deep-name", base_name}
end

local function find_item_that_places(entity_name)
  for prototype_type, prototypes in pairs(data.raw or {}) do
    if type(prototypes) == "table" then
      for _, prototype in pairs(prototypes) do
        if type(prototype) == "table" and prototype.place_result == entity_name and type(prototype.name) == "string" then
          return prototype, prototype_type
        end
      end
    end
  end

  return nil, nil
end

local function product_item_name(product)
  if type(product) ~= "table" then
    return nil
  end

  local product_type = product.type or "item"
  if product_type ~= "item" then
    return nil
  end

  return product.name or product[1]
end

local function recipe_products(recipe)
  local products = {}

  if type(recipe.results) == "table" then
    for _, product in pairs(recipe.results) do
      if type(product) == "table" then
        table.insert(products, product)
      end
    end
  elseif recipe.result then
    table.insert(products, {
      type = "item",
      name = recipe.result,
      amount = recipe.result_count or 1
    })
  end

  return products
end

local function find_recipe_for_item(item_name)
  local candidates = {}

  for _, recipe in pairs(data.raw.recipe or {}) do
    if type(recipe) == "table" and not is_deep_name(recipe.name) then
      local products = recipe_products(recipe)
      for _, product in pairs(products) do
        if product_item_name(product) == item_name then
          local score = 1
          if recipe.name == item_name then
            score = 4
          elseif recipe.main_product == item_name then
            score = 3
          elseif #products == 1 then
            score = 2
          end

          table.insert(candidates, {recipe = recipe, product = product, score = score})
        end
      end
    end
  end

  if #candidates == 0 then
    return nil, nil, "no recipe produces item '" .. item_name .. "'"
  end

  local best_score = -1
  local best_candidates = {}
  for _, candidate in pairs(candidates) do
    if candidate.score > best_score then
      best_score = candidate.score
      best_candidates = {candidate}
    elseif candidate.score == best_score then
      table.insert(best_candidates, candidate)
    end
  end

  if #best_candidates == 1 then
    return best_candidates[1].recipe, best_candidates[1].product, nil
  end

  return nil, nil, "multiple recipes produce item '" .. item_name .. "' with the same confidence"
end

local function product_amount_for_ingredient(product)
  if type(product) ~= "table" then
    return 1
  end

  if type(product.amount) == "number" then
    return math.max(1, product.amount)
  end

  if type(product.amount_min) == "number" then
    return math.max(1, product.amount_min)
  end

  return 1
end

local function build_result_product(source_product, deep_item_name)
  local result = deepcopy(source_product)
  result.type = "item"

  if result.name then
    result.name = deep_item_name
  else
    result[1] = deep_item_name
  end

  return result
end

local function ingredient_item_name(ingredient)
  if type(ingredient) ~= "table" then
    return nil
  end

  local ingredient_type = ingredient.type or "item"
  if ingredient_type ~= "item" then
    return nil
  end

  return ingredient.name or ingredient[1]
end
local function add_item_ingredient(ingredients, item_name, amount)
  for _, ingredient in pairs(ingredients) do
    if ingredient_item_name(ingredient) == item_name then
      if ingredient.amount then
        ingredient.amount = ingredient.amount + amount
      elseif ingredient[2] then
        ingredient[2] = ingredient[2] + amount
      else
        ingredient.amount = amount + 1
      end
      return
    end
  end

  table.insert(ingredients, {type = "item", name = item_name, amount = amount})
end

local function recipe_is_disabled(recipe)
  return recipe.enabled == false
end

local function technology_unlocks_recipe(technology, recipe_name)
  if type(technology.effects) ~= "table" then
    return false
  end

  for _, effect in pairs(technology.effects) do
    if type(effect) == "table" and effect.type == "unlock-recipe" and effect.recipe == recipe_name then
      return true
    end
  end

  return false
end

local function add_unlock_to_source_technologies(source_recipe_name, deep_recipe_name)
  local unlock_count = 0

  for _, technology in pairs(data.raw.technology or {}) do
    if type(technology) == "table" and technology_unlocks_recipe(technology, source_recipe_name) then
      if not technology_unlocks_recipe(technology, deep_recipe_name) then
        if type(technology.effects) ~= "table" then
          technology.effects = {}
        end
        table.insert(technology.effects, {type = "unlock-recipe", recipe = deep_recipe_name})
      end
      unlock_count = unlock_count + 1
    end
  end

  return unlock_count
end

local function retarget_minable(entity, deep_item_name)
  if type(entity.minable) ~= "table" then
    return
  end

  if entity.minable.result then
    entity.minable.result = deep_item_name
    return
  end

  if type(entity.minable.results) == "table" then
    for _, product in pairs(entity.minable.results) do
      if type(product) == "table" and (product.type == nil or product.type == "item") then
        if product.name then
          product.name = deep_item_name
        elseif product[1] then
          product[1] = deep_item_name
        end
        return
      end
    end
  end
end

local function retarget_placeable_by(placeable_by, source_item_name, deep_item_name)
  if type(placeable_by) ~= "table" then
    return placeable_by
  end

  local copy = deepcopy(placeable_by)
  if copy.item == source_item_name then
    copy.item = deep_item_name
    return copy
  end

  for _, item_to_place in pairs(copy) do
    if type(item_to_place) == "table" and item_to_place.item == source_item_name then
      item_to_place.item = deep_item_name
    end
  end

  return copy
end

local function retarget_underground_pipe_connections(pipe_to_ground, connection_category)
  local fluid_box = type(pipe_to_ground.fluid_box) == "table" and pipe_to_ground.fluid_box or nil
  if type(fluid_box) ~= "table" or type(fluid_box.pipe_connections) ~= "table" then
    return false
  end

  local changed = false
  for _, pipe_connection in pairs(fluid_box.pipe_connections) do
    if type(pipe_connection) == "table" and pipe_connection.connection_type == "underground" then
      pipe_connection.connection_category = connection_category
      changed = true
    end
  end

  return changed
end

local function make_deep_recipe(deep_name, source_item, source_recipe, source_product)
  local recipe = deepcopy(source_recipe)
  recipe.name = deep_name
  recipe.localised_name = deep_localised_name(source_item, "item")
  recipe.localised_description = {"extended-undergrounds.deep-recipe-description"}
  recipe.icon = nil
  recipe.icon_size = nil
  recipe.icon_mipmaps = nil
  recipe.icons = nil
  recipe.result = nil
  recipe.result_count = nil
  recipe.results = {build_result_product(source_product, deep_name)}
  recipe.main_product = deep_name
  recipe.ingredients = deepcopy(source_recipe.ingredients or {})
  add_item_ingredient(recipe.ingredients, source_item.name, product_amount_for_ingredient(source_product))

  return recipe
end

local function build_deep_prototypes(source_type, source_name, source_entity, tint_graphics, mutate_entity)
  if is_deep_name(source_name) then
    return nil
  end

  local deep_name = deep_name_for(source_name)
  if prototype_exists(source_type, deep_name) or prototype_exists("recipe", deep_name) then
    write_log("Skipping '" .. source_name .. "' because generated entity or recipe name already exists: '" .. deep_name .. "'.")
    return nil
  end

  local source_item, source_item_type = find_item_that_places(source_name)
  if not source_item then
    write_log("Skipping '" .. source_name .. "' because no item with place_result='" .. source_name .. "' was found.")
    return nil
  end

  if prototype_exists(source_item_type, deep_name) then
    write_log("Skipping '" .. source_name .. "' because generated item name already exists: '" .. deep_name .. "'.")
    return nil
  end

  local source_recipe, source_product, recipe_error = find_recipe_for_item(source_item.name)
  if not source_recipe then
    write_log("Skipping '" .. source_name .. "' because " .. recipe_error .. ".")
    return nil
  end

  local deep_entity = deepcopy(source_entity)
  deep_entity.name = deep_name
  deep_entity.localised_name = deep_localised_name(source_entity, "entity")
  deep_entity.localised_description = {"extended-undergrounds.deep-entity-description"}
  deep_entity.factoriopedia_alternative = nil
  deep_entity.next_upgrade = nil

  if deep_entity.fast_replaceable_group then
    deep_entity.fast_replaceable_group = DEEP_PREFIX .. deep_entity.fast_replaceable_group
  end

  if deep_entity.placeable_by then
    deep_entity.placeable_by = retarget_placeable_by(deep_entity.placeable_by, source_item.name, deep_name)
  end

  retarget_minable(deep_entity, deep_name)
  apply_tinted_icons(deep_entity, source_entity)
  tint_graphics(deep_entity)

  if mutate_entity then
    local ok, reason = mutate_entity(deep_entity, deep_name)
    if not ok then
      write_log("Skipping '" .. source_name .. "' because " .. reason .. ".")
      return nil
    end
  end

  local deep_item = deepcopy(source_item)
  deep_item.name = deep_name
  deep_item.place_result = deep_name
  deep_item.localised_name = deep_localised_name(source_item, "item")
  deep_item.localised_description = {"extended-undergrounds.deep-item-description"}
  deep_item.factoriopedia_alternative = nil
  apply_tinted_icons(deep_item, source_item)

  local deep_recipe = make_deep_recipe(deep_name, source_item, source_recipe, source_product)
  if recipe_is_disabled(source_recipe) then
    local unlock_count = add_unlock_to_source_technologies(source_recipe.name, deep_name)
    if unlock_count == 0 then
      write_log("Created disabled recipe '" .. deep_name .. "' but found no technology unlocking source recipe '" .. source_recipe.name .. "'.")
    end
  end

  return {
    source_name = source_name,
    deep_name = deep_name,
    source_entity = source_entity,
    entity = deep_entity,
    item = deep_item,
    item_type = source_item_type,
    recipe = deep_recipe
  }
end

local function add_deep_entries(entries, new_prototypes)
  local deep_name_by_source_name = {}

  for _, entry in pairs(entries) do
    deep_name_by_source_name[entry.source_name] = entry.deep_name
  end

  for _, entry in pairs(entries) do
    local source_next_upgrade = entry.source_entity.next_upgrade
    if source_next_upgrade and deep_name_by_source_name[source_next_upgrade] then
      entry.entity.next_upgrade = deep_name_by_source_name[source_next_upgrade]
    end

    table.insert(new_prototypes, entry.entity)
    table.insert(new_prototypes, entry.item)
    table.insert(new_prototypes, entry.recipe)
  end
end

local belt_multiplier = startup_setting_value("extended-undergrounds-belt-distance-multiplier", 1.0)
local pipe_multiplier = startup_setting_value("extended-undergrounds-pipe-distance-multiplier", 1.0)
local add_deep_belts = startup_setting_value("extended-undergrounds-add-deep-underground-belts", true)
local add_deep_pipes = startup_setting_value("extended-undergrounds-add-deep-pipe-to-ground", true)

for name, underground_belt in pairs(data.raw["underground-belt"] or {}) do
  if not is_deep_name(name) and type(underground_belt) == "table" and type(underground_belt.max_distance) == "number" then
    underground_belt.max_distance = scaled_underground_distance(underground_belt.max_distance, belt_multiplier)
  end
end

for name, pipe_to_ground in pairs(data.raw["pipe-to-ground"] or {}) do
  if not is_deep_name(name) then
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
end

local new_prototypes = {}

if add_deep_belts then
  local belt_entries = {}
  for name, underground_belt in pairs(data.raw["underground-belt"] or {}) do
    if type(underground_belt) == "table" then
      local entry = build_deep_prototypes("underground-belt", name, underground_belt, tint_underground_belt_graphics)
      if entry then
        table.insert(belt_entries, entry)
      end
    end
  end
  add_deep_entries(belt_entries, new_prototypes)
end

if add_deep_pipes then
  local pipe_entries = {}
  for name, pipe_to_ground in pairs(data.raw["pipe-to-ground"] or {}) do
    if type(pipe_to_ground) == "table" then
      local entry = build_deep_prototypes("pipe-to-ground", name, pipe_to_ground, tint_pipe_to_ground_graphics, function(deep_entity, deep_name)
        if retarget_underground_pipe_connections(deep_entity, deep_name) then
          return true
        end

        return false, "no underground pipe connection with connection_type='underground' was found"
      end)
      if entry then
        table.insert(pipe_entries, entry)
      end
    end
  end
  add_deep_entries(pipe_entries, new_prototypes)
end

if #new_prototypes > 0 then
  data:extend(new_prototypes)
end
