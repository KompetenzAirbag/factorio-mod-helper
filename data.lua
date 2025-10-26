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

local old_extend = data.extend
data.extend = function(self, t)
  if (helper.extend) then
    execute_extender(helper.extend, t)
  end
  old_extend(self, t)
end