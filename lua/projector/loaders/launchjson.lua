local Task = require("projector.task")
local Loader = require("projector.contract.loader")
local common = require("projector.loaders.common")

---@type Loader
local LaunchJsonLoader = Loader:new("legacy.json")

---@param opt string Path to legacy projector.json
---@return Task[]|nil
function LaunchJsonLoader:load(opt)
  local path = opt or (vim.fn.getcwd() .. "/.vscode/launch.json")
  if type(path) ~= "string" then
    print("LaunchJsonLoader error: got " .. type(path) .. ", want string")
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
    vim.notify(
      '[launch.json Loader] Error parsing json file: "' .. path .. '"',
      vim.log.levels.ERROR,
      { title = "nvim-projector" }
    )
    return
  end

  local function convert_config(launch_config)
    -- translate field names
    -- launch_config.name = launch_config.name
    launch_config.dependencies = { launch_config.preLaunchTask }
    launch_config.after = launch_config.postDebugTask
    -- launch_config.env = launch_config.env
    -- launch_config.cwd = launch_config.cwd
    -- launch_config.args =launch_config.args
    -- launch_config.command =launch_config.command
    -- launch_config.type = launch_config.type
    -- launch_config.request = launch_config.request
    -- launch_config.program = launch_config.program
    -- launch_config.port = launch_config.port

    local group = launch_config.type or "launch"

    return Task:new(launch_config, { scope = "project", group = group })
  end

  -- map with Task objects
  local tasks = {}

  if data.configurations then
    for _, config in pairs(data.configurations) do
      local task = convert_config(config)
      table.insert(tasks, task)
    end
  end

  return tasks
end

-- We can use already configured variable expansion
---@param configuration Configuration
---@return Configuration
function LaunchJsonLoader:expand_variables(configuration)
  return vim.tbl_map(common.expand_config_variables, configuration)
end

return LaunchJsonLoader
