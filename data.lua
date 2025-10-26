if not helper then
    helper = {}
end

local function json_escape(str)
  -- Escape backslashes, quotes, and control characters
  str = str:gsub('\\', '\\\\')
  str = str:gsub('"', '\\"')
  str = str:gsub('\n', '\\n')
  str = str:gsub('\r', '\\r')
  str = str:gsub('\t', '\\t')
  return str
end

function helper.dump(o)
  local t = type(o)
  if t == "table" then
    -- detect if the table is an array (all numeric, 1..n)
    local is_array = true
    local max_index = 0
    for k, _ in pairs(o) do
      if type(k) ~= "number" then
        is_array = false
        break
      else
        if k > max_index then max_index = k end
      end
    end

    local parts = {}
    if is_array then
      for i = 1, max_index do
        table.insert(parts, helper.dump(o[i]))
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      for k, v in pairs(o) do
        table.insert(parts, '"' .. json_escape(tostring(k)) .. '":' .. helper.dump(v))
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end

  elseif t == "string" then
    return '"' .. json_escape(o) .. '"'
  elseif t == "number" or t == "boolean" then
    return tostring(o)
  elseif t == "nil" then
    return "null"
  else
    return '"<' .. t .. '>"' -- fallback
  end
end

function log_item(name)
  log(helper.dump(data.raw.item[name]))
end

function log_recipe(name)
  log(helper.dump(data.raw.recipe[name]))
end

function log_tech(name)
  log(helper.dump(data.raw["technology"][name]))
end

function log_table(table)
  log(helper.dump(table))
end

---This can be a function, a string (will get printed) or a table
---A string will get printed
---A function will get executed and takes in the arguments passed to data:extend
---A table will get iterated and every string printed and functions executed
helper["extend"] = nil

local function execute_extender(extend, t)
  if (type(extend) == "table") then
    for _, _extend in pairs(extend) do
      execute_extender(_extend)
    end
  elseif (type(extend) == "function") then
    extend(t)
  elseif (type(extend) == "string") then
    log(extend)
  end
end

---Usage:
---Go to the top of the data.lua file of the mod you want to extend
---Add: helper.extend = function(args) ...YOUR FUNCTION... end
---Anything done to data will go through your extended function (see above)
---At the end of the data.lua file add helper.extend = nil to stop
local old_extend = data.extend
data.extend = function(self, t)
  if (helper.extend) then
    execute_extender(helper.extend, t)
  end
  old_extend(self, t)
end

---Iterates all mods and specifically searches for mod names
---Putting this here will include all stages (data, data-updates, data-final-fixes)
---@param mod_name string this can be part of a name (e.g. "angels" for all angels mods)
---@param mod_prefix string this can also be part of a prefix
local function prefix_check_all_mods(mod_name, mod_prefix)
  local internal_mod_name = ""
  new_name = false

  helper.extend = function(arg)
    local info = debug.getinfo(4, "S").source
    info = info:match("@__([%w%-%_]+)__")
    if not string.find(info, mod_name) then
      return
    end

    if internal_mod_name ~= info then
      internal_mod_name = info
      new_name = true
    end

    for _,ext in pairs(arg) do
      if not string.find(ext.name, mod_prefix) then
        if new_name then
          print(internal_mod_name)
          new_name = false
        end

        print("name: "..ext.name.." | type: "..ext.type)
      end
    end
  end
end

prefix_check_all_mods("angels", "angels-")