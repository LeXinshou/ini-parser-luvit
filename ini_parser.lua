local fs = require("fs")

local M = {}

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function unquote(value)
  local first = value:sub(1, 1)
  local last = value:sub(-1)
  if (#value >= 2) and ((first == '"' and last == '"') or (first == "'" and last == "'")) then
    return value:sub(2, -2)
  end
  return value
end

local function parseValue(raw)
  local value = trim(raw)
  local lower = value:lower()

  if lower == "true" then return true end
  if lower == "false" then return false end

  local number = tonumber(value)
  if number ~= nil then return number end

  return unquote(value)
end

local function stripInlineComment(value)
  local quote = nil

  for i = 1, #value do
    local ch = value:sub(i, i)
    if ch == '"' or ch == "'" then
      if quote == ch then
        quote = nil
      elseif not quote then
        quote = ch
      end
    elseif (ch == ";" or ch == "#") and not quote then
      return trim(value:sub(1, i - 1))
    end
  end

  return trim(value)
end

function M.parse(input)
  assert(type(input) == "string", "ini.parse expects a string")

  local result = {}
  local current = result
  local text = input:gsub("^\239\187\191", "")

  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    local raw = trim(line)

    if raw ~= "" and raw:sub(1, 1) ~= ";" and raw:sub(1, 1) ~= "#" then
      local sectionName = raw:match("^%[(.-)%]$")
      if sectionName then
        sectionName = trim(sectionName)
        if result[sectionName] == nil then
          result[sectionName] = {}
        end
        current = result[sectionName]
      else
        local key, value = raw:match("^([^=]+)%s*=%s*(.*)$")
        if key then
          key = trim(key)
          value = stripInlineComment(value)
          current[key] = parseValue(value)
        end
      end
    end
  end

  return result
end

M.decode = M.parse

function M.parseFile(path)
  local content = assert(fs.readFileSync(path))
  return M.parse(content)
end

M.decodeFile = M.parseFile

return M
