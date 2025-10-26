local function remove_recipes_from_handcrafting()
  player_categories = {}

  for _, v in pairs(data.raw.character) do
    v.crafting_categories = v.crafting_categories or {}
    
    player_categories = v.crafting_categories
  end

  local function find_in_array(name)
    for _,cat in pairs(player_categories) do
      if (cat == name) then
        return true
      end
    end

    return false
  end

  local function is_craftable(recipe)
    if (not recipe.category and (not recipe.additional_categories or #recipe.additional_categories == 0)) then
      return true
    end

    if (find_in_array(recipe.category)) then
      return true
    end

    for _, name in pairs(recipe.additional_categories or {}) do
      if (find_in_array(name)) then
        return true
      end
    end

    return false
  end

  for _, recipe in pairs(data.raw.recipe) do
    if (not is_craftable(recipe)) then
      recipe.hide_from_player_crafting = true
    end
  end
end

if settings.startup["hp-only-show-handcraftables"].value then
  remove_recipes_from_handcrafting()
end