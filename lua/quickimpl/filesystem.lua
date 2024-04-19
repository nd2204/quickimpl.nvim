local M = {}

local helper = require("quickimpl.helper")
local api = vim.api
local ts = vim.treesitter
local uv = vim.uv

--- Extend the vim.fs api
M.fs = vim.fs
-- local helper = require("quickimpl.helper")

local exension_index = {
  ['.hpp'] = '.cpp',
  ['.h'] = '.cpp',
  ['.hh'] = '.cc',
  ['.hxx'] = '.cxx',
  ['.h++'] = '.c++',
  ['.H'] = '.C',
}

-- TODO: Let the user choose where to store the 
-- generated definitions in config.lua
local source_dir_names = { 'source', 'src' }
local include_dir_names = { 'include', 'inc' }

local function isValidPath(path)
  return vim.fn.filereadable(path) ~= 0
end

local function base_dirname(path)
  path = fs.dirname(path)
  return path and fs.basename(path) or nil
end

---This function will attempt to retrieve
---@param path (string | nil)
---@param height (integer)
---@return (string | nil) modified_path
local function M.get_parent_dir(path, height)
  height = height and height or 1
  if path == nil then
     return nil
  end
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
local function attempt_to_get_source_dir(headerfile_path)
  -- utilize vim.fs library to get the basename and dirname
  -- instead of custom function defines
  headerfile_path = M.fs.normalize(headerfile_path)
  assert(headerfile_path,
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): headerfile_path is nil" )
  assert(headerfile_path ~= '',
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): headerfile_path is empty"
  )
  assert(isValidPath(headerfile_path),
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): headerfile_path is not a valid path"
  )

  local currentDir      = helper.default_if_nil(headerfile_path, M.fs.dirname(headerfile_path))
  -- local headerfile_name = fs.basename(headerfile_path)

  --- TODO: let user choose which source dir to save the source file
  local stopDir = M.get_parent_dir(currentDir, 2)
  stopDir = helper.default_if_nil(currentDir, stopDir)
  local source_dir_paths = fs.find(source_dir_names, {
    path    = headerfile_path,
    upward  = true,
    -- set stop to currentDir if currentDir has no parents
    stop    = stopDir,
    type    = 'directory',
    limit   = math.huge
  })

  if source_dir_paths[1] ~= nil then
    return M.fs.normalize(source_dir_paths[1] .. "/")
  end

  return currentDir
end

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------

---@param headerfile_path (string)
---@return (string | nil) sourcefile_path
---This function
function M.get_sourcefile_equivalence(headerfile_path)
  headerfile_path = M.fs.normalize(headerfile_path)
  local headerfile_name = M.fs.basename(headerfile)
  local currentDir      = M.fs.dirname(headerfile_path)
  --- %. match a literal period;
  --- ([^%.]+)$ matches one or more characters that are not periods.
  --- This captures the extension characters. and anchor the pattern 
  --- to the end of the string
  local headerfile_ext  = headerfile_path:match("(%.[^%.]+)$")
  --- TODO: change the default nil value to support both c and cpp
  headerfile_ext = headerfile_ext and headerfile_ext or ".hpp"
  local sourcefile_ext = exension_index[headerfile_ext]
  assert(sourcefile_ext, "Error: unsupported header extension " .. headerfile_ext)

  local sourcefile_name = string.gsub(headerfile_name, headerfile_ext, sourcefile_ext)

  --- concatenate "/" to a path_string or any variables is EXCEPTIONALLY DANGEROUS proceed with caution
  local sourcedir_path = attempt_to_get_source_dir(headerfile_path)
  local sourcefile_path = sourcedir_path .. "/" .. sourcefile_name .. sourcefile_ext

  print(sourcefile_path)
  -- local directory = base_dirname(source_path)
  -- if directory == nil then
  --   return source_path
  -- end
  -- for i = 1, #include_dir_names do
  --   if include_dir_names[string.lower(directory)] then
  --     source_path = attempt_to_get_source_dir(source_path)
  --   end
  -- end

  -- return source_path
end

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
  path = M.fs.normalize(path)
  local fd = uv.fs_open(path, 'a', 438)
  uv.fs_write(fd, content .. '\n\n', 0)
  uv.fs_close(fd)
end

print(M.get_sourcefile_equivalence('~/repos/code/lang/cpp/test/include/test.hpp'))
-- print(attempt_to_change_to_source_dir('/test.hpp'))

return M
