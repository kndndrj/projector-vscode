local common = require("projector.loaders.common")

---@class LaunchJsonLoader: Loader
---@field private get_path fun():string function that returns a path to launch.json file
local LaunchJsonLoader = {}

---@param opts? { path: string|fun():(string), }
---@return LaunchJsonLoader
function LaunchJsonLoader:new(opts)
  opts = opts or {}

  local path_getter
  if type(opts.path) == "string" then
    path_getter = function()
      return opts.path
    end
  elseif type(opts.path) == "function" then
    path_getter = function()
      return opts.path() or vim.fn.getcwd() .. "/.vscode/launch.json"
    end
  end

  local o = {
    get_path = path_getter or function()
      return ""
    end,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

---@return string
function LaunchJsonLoader:name()
  return "launch.json"
end

---@return task_configuration[]?
function LaunchJsonLoader:load()
  if not vim.loop.fs_stat(self.get_path()) then
    return
  end

  local lines = {}
  for line in io.lines(self.get_path()) do
    if not vim.startswith(vim.trim(line), "//") then
      table.insert(lines, line)
    end
  end

  local contents = table.concat(lines, "\n")
  local ok, data = pcall(vim.fn.json_decode, contents)
  if not ok then
    return
  end

  local function convert_config(config)
    -- translate field names
    -- config.name = config.name
    config.dependencies = { config.preLaunchTask }
    config.after = config.postDebugTask
    -- config.env = config.env
    -- config.cwd = config.cwd
    -- config.args =config.args
    -- config.command =config.command
    -- config.type = config.type
    -- config.request = config.request
    -- config.program = config.program
    -- config.port = config.port
    config.group = config.type or "launch"
    config.scope = "project"

    return config
  end

  -- map with Task objects
  ---@type task_configuration[]
  local configs = {}

  if data.configurations then
    for _, config in ipairs(data.configurations) do
      table.insert(configs, convert_config(config))
    end
  end

  return configs
end

-- We can use already configured variable expansion
---@param configuration task_configuration
---@return task_configuration
function LaunchJsonLoader:expand(configuration)
  return vim.tbl_map(common.expand_config_variables, configuration)
end

---@return string
function LaunchJsonLoader:file()
  return self.get_path()
end

return LaunchJsonLoader
