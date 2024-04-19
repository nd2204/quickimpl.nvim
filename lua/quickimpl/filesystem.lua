local M = {}

local api = vim.api
local ts = vim.treesitter
local uv = vim.uv
local fs = vim.fs

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

local function is_user_defined_source_directory(name, type)
    for i = 1, #source_dir_names do
      if source_dir_names[string.lower(name)] ~= nil and type == 'directory' then
        return true
      end
    end
end

local function is_user_defined_include_directory(name, type)
    for i = 1, #include_dir_names do
      if include_dir_names[string.lower(name)] ~= nil and type == 'directory' then
        return true
      end
    end
end

---@param headerfile_path string
---@return (string) source_dir_path (modified or unmodified)
---[
---Seach upward (if possible) from current directory 
---the parents directory for the source directory 
---If found return the path to that directory
---Else return the unchanged headerfile_path (remain in that path)
---]
local function attempt_to_change_to_source_dir(headerfile_path)
  -- utilize vim.fs library to get the basename and dirname
  -- instead of custom function defines
  assert(headerfile_path,
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): headerfile_path is nil" )
  assert(headerfile_path ~= '',
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): headerfile_path is empty"
  )
  assert(vim.fn.isdirectory(headerfile_path),
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): headerfile_path is not a valid path"
  )

  local source_dir_path = headerfile_path
  local currentDir      = fs.dirname(headerfile_path)
  local headerfile_name = fs.basename(headerfile_path)

  local stopDir = fs.dirname(fs.dirname(currentDir))
  stopDir = stopDir and stopDir or currentDir
  local matches = fs.find(source_dir_names, {
    path    = headerfile_path,
    upward  = true,  
    -- set stop to currentDir if currentDir has no parents
    stop    = stopDir,
    type    = 'directory',
    limit   = 1
  })

  if matches[1] ~= nil then
    return fs.normalize(matches[1] .. "/")
  end

  return currentDir
end

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------

---@param headerfile_path (string)
---@return (string | nil)
---
function M.get_sourcefile_equivalence(headerfile_path)
  local sourcefile_ext = ''
  local headerfile_ext = ''
  for w in string.gmatch(headerfile_path, '%.%w+') do
    sourcefile_ext = exension_index[w]
    headerfile_ext = w
  end

  if sourcefile_ext == '' or headerfile_ext == '' then
    return nil
  end

  headerfile_ext = '%' .. headerfile_ext
  local source_path = string.gsub(headerfile_path, headerfile_ext, sourcefile_ext)

  -- If a project has separate directories for source files and
  -- header files, placing the source file in the header directory
  -- will be incorrect. Thus if we can detect that the header is
  -- in an "include" directory we can attempt to find the "source"
  -- directory.
  local directory = fs.basename(fs.dirname(source_path))
  for i = 1, #include_dir_names do
    if string.lower(directory) == include_dir_names[i] then
      source_path = attempt_to_change_to_source_dir(source_path)
    end
  end

  return source_path
end

function M.open_file_in_buffer(path)
  api.nvim_command('e ' .. path)
  local bufnr = api.nvim_get_current_buf()
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  return root, bufnr
end

function M.append_to_file(path, content)
  local fd = uv.fs_open(path, 'a', 438)
  uv.fs_write(fd, content .. '\n\n', 0)
  uv.fs_close(fd)
end

print(M.('/home/haru/repos/code/lang/cpp/test/include/test.hpp'))
-- print(attempt_to_change_to_source_dir('/test.hpp'))

return M
