local Task = require("projector.task")
local Loader = require("projector.contract.loader")
local common = require("projector.loaders.common")
local utils = require("projector.utils")

---@type Loader
local TasksJsonLoader = Loader:new()

---@return Task[]|nil
function TasksJsonLoader:load()
  ---@type { path: string }
  local opts = self.user_opts

  local path = opts.path or (vim.fn.getcwd() .. "/.vscode/tasks.json")
  if type(path) ~= "string" then
    utils.log("error", 'Got: "' .. type(path) .. '", want "string".', "tasks.json Loader")
    return
  end

  if not vim.loop.fs_stat(path) then
    return
  end

  local lines = {}
  for line in io.lines(path) do
    if not vim.startswith(vim.trim(line), "//") then
      table.insert(lines, line)
    end
  end

  local contents = table.concat(lines, "\n")
  local ok, data = pcall(vim.fn.json_decode, contents)
  if not ok then
    utils.log("error", 'Could not parse json file: "' .. path .. '".', "tasks.json Loader")
    return
  end

  local function convert_config(task_config)
    local cwd
    local env
    if task_config.options then
      env = task_config.options.env
      cwd = task_config.options.cwd
    end
    local pattern
    if task_config.problemMatcher then
      if task_config.problemMatcher.pattern then
        pattern = task_config.problemMatcher.pattern.regexp
      end
    end

    -- translate field names
    task_config.name = task_config.label or task_config.taskName
    task_config.dependencies = task_config.dependsOn
    task_config.env = env
    task_config.cwd = cwd
    --task_config.args =task_config.args
    task_config.pattern = pattern
    --task_config.command =task_config.command

    local group = task_config.group or task_config.type or "task"

    return Task:new(task_config, { scope = "project", group = group })
  end

  -- map with Task objects
  local tasks = {}

  if data.command then
    local config = data
    local task = convert_config(config)
    table.insert(tasks, task)
  end

  if data.tasks then
    for _, config in pairs(data.tasks) do
      local task = convert_config(config)
      table.insert(tasks, task)
    end
  end

  return tasks
end

-- We can use already configured variable expansion
---@param configuration Configuration
---@return Configuration
function TasksJsonLoader:expand_variables(configuration)
  return vim.tbl_map(common.expand_config_variables, configuration)
end

return TasksJsonLoader
