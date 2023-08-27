local common = require("projector.loaders.common")

---@class TasksJsonLoader: Loader
---@field private get_path fun():string function that returns a path to launch.json file
local TasksJsonLoader = {}

---@param opts? { path: string|fun():(string), }
---@return TasksJsonLoader
function TasksJsonLoader:new(opts)
  opts = opts or {}

  local path_getter
  if type(opts.path) == "string" then
    path_getter = function()
      return opts.path
    end
  elseif type(opts.path) == "function" then
    path_getter = function()
      return opts.path() or vim.fn.getcwd() .. "/.vscode/tasks.json"
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
function TasksJsonLoader:name()
  return "tasks.json"
end

---@return Task[]|nil
function TasksJsonLoader:load()
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
    local cwd
    local env
    if config.options then
      env = config.options.env
      cwd = config.options.cwd
    end
    local pattern
    if config.problemMatcher then
      if config.problemMatcher.pattern then
        pattern = config.problemMatcher.pattern.regexp
      end
    end

    -- translate field names
    config.name = config.label or config.taskName
    config.dependencies = config.dependsOn
    config.env = env
    config.cwd = cwd
    --config.args = config.args
    config.pattern = pattern
    --config.command = config.command

    config.group = config.group or config.type or "task"
    config.scope = "project"

    return config
  end

  -- map with Task objects
  local tasks = {}

  if data.command then
    table.insert(tasks, convert_config(data))
  end

  if data.tasks then
    for _, config in pairs(data.tasks) do
      table.insert(tasks, convert_config(config))
    end
  end

  return tasks
end

-- We can use already configured variable expansion
---@param configuration task_configuration
---@return task_configuration
function TasksJsonLoader:expand(configuration)
  return vim.tbl_map(common.expand_config_variables, configuration)
end

---@return string
function TasksJsonLoader:file()
  return self.get_path()
end

return TasksJsonLoader
