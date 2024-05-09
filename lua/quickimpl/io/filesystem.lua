local M = {}

local api = vim.api
local ts = vim.treesitter
local uv = vim.uv
local cfg = require("quickimpl.config")
local fs = vim.fs
--- Extend the vifs api
-- local helper = require("quickimpl.helper")

local exension_index = {
  c = {
    ['.h'] = '.c',
    ['.hh'] = '.cc',
    ['.H'] = '.C',
  },
  cpp = {
    ['.hpp'] = '.cpp',
    ['.h'] = '.cpp',
    ['.h++'] = '.c++',
    ['.hxx'] = '.cxx',
  }
}

local source_dir_names = { 'source', 'src' }
local include_dir_names = { 'include', 'inc' }

function M.is_path_valid(path)
  return vim.fn.filereadable(path) ~= 0
end

---@param path (string)
---@return (string)
function M.get_ext(path)
  return path:match("(%.[^%.]+)$")
end

---@param path (string)
---@param ext (string)
function M.change_ext(path, ext)
  return string.gsub(path, M.get_ext(path), ext)
end

function M.base_dirname(path)
  if not path then return nil end
  path = fs.dirname(path)
  return path and fs.basename(path) or nil
end

---This function will attempt to retrieve
---@param path (string | nil)
---@param height (integer)
---@return (string | nil) modified_path
function M.get_parent_dir(path, height)
  height = height or 1
  if not path then return nil end
  path = fs.normalize(path)
  for _ = 1, height do
    path = fs.dirname(path)
  end
  return path
end

-- local function is_user_defined_include_directory(name, type)
--     for i = 1, #include_dir_names do
--       if include_dir_names[string.lower(name)] ~= nil and type == 'directory' then
--         return true
--       end
--     end
-- end

---@param headerfile_path string
---@return (string) source_dir_path (modified or unmodified)
---[
---Seach upward (if possible) from current directory 
---the parents directory for the source directory 
---If found return the path to that directory
---Else return the unchanged headerfile_path (remain in that path)
---]
local function attempt_to_get_source_dir(path)
  -- utilize vifs library to get the basename and dirname
  -- instead of custom function defines
  path = fs.normalize(path)
  assert(path,
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): path is nil" )
  assert(path ~= '',
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): path is empty"
  )
  assert(M.is_path_valid(path),
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): path is not a valid path"
  )

  local currentDir = assert(fs.dirname(path))
  -- local headerfile_name = fs.basename(headerfile_path)

  --- TODO: let user choose which source dir to save the source file
  local stopDir = M.get_parent_dir(currentDir, 2)
  stopDir = currentDir and currentDir or stopDir
  local source_dir_paths = fs.find(source_dir_names, {
    path    = path,
    upward  = true,
    -- set stop to currentDir if currentDir has no parents
    stop    = stopDir,
    type    = 'directory',
    limit   = math.huge
  })

  if source_dir_paths[1] == nil then
    return currentDir
  end

  return fs.normalize(source_dir_paths[1])
end

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------

---@param headerfile_path (string)
---@return (string) sourcefile_path
---This function
function M.get_sourcefile_equivalence(headerfile_path, lang)
  headerfile_path = fs.normalize(headerfile_path)
  local headerfile_name = assert(fs.basename(headerfile_path))
  --- TODO: change the default nil value to support both c and cpp
  local sourcefile_ext = assert(exension_index[lang][M.get_ext(headerfile_name)])
  local sourcefile_name = M.change_ext(headerfile_name, sourcefile_ext)

  local sourcedir_path = attempt_to_get_source_dir(headerfile_path)
  local sourcefile_path = fs.joinpath(sourcedir_path, sourcefile_name)

  print(sourcefile_path)

  return sourcefile_path
end

---@param path (string)
function M.open_file_in_buffer(path)
  api.nvim_command('e ' .. path)
  local bufnr = api.nvim_get_current_buf()
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  return root, bufnr
end

---@param path (string)
---@param content (string)
function M.file_append_content(path, content)
  path = fs.normalize(path)
  local fd = uv.fs_open(path, 'a', 438)
  assert(fd ~= nil, "Unable to open file: "..path)
  uv.fs_write(fd, content .. '\n', 0)
  uv.fs_close(fd)
end

-- M.get_sourcefile_equivalence("/home/haru/repos/code/design-patterns/decorator/starbuzz/beverage/beverages/coffees.hpp","cpp")

return M
