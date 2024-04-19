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

local function is_user_defined_source_directory(name, type)
    for i = 1, #source_dir_names do
      if source_dir_names[i] == string.lower(name) and type == 'directory' then
        return true
      end
    end
end
---@param source_path string
---@return (string) source_path (modified or unmodified)
local function attempt_to_change_to_source_dir(source_path)
  -- Remove last directory
  -- Scan it
  -- Decide whether it has source directory
  --     If yes, replace path part with the directory name
  --     Else return source_path

  -- utilize vim.fs library to get the basename and dirname
  -- instead of custom function defines
  assert(
    source_path ~= '' and source_path,
    "ERROR (at line:" .. debug.getinfo(1).currentline .. "): source_path is nil"
  )

  local directory_above = source_path
  local count = 0;
  for _ in fs.parents(source_path) do
    count = count + 1
  end

  if count > 2 then
    directory_above = fs.dirname(fs.dirname(source_path))
  end

  local filename = fs.basename(source_path)

  local files = uv.fs_scandir(directory_above)
  local name, type = uv.fs_scandir_next(files)
  -- vim.inspect(name)
  print(name)
  local ok = false
  while name ~= nil do
    if is_user_defined_source_directory(name, type) then
      return directory_above .. '/' .. name .. filename
    end
    ok, name, type = pcall(fs.fs_scandir_next, files) 
    if not ok then
      return source_path
    end
    name, type = fs.fs_scandir_next(files)
  end

  return source_path
end

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------

---@return (string | nil)
function M.header_to_source(header_name)
  local sourcefile_ext = ''
  local headerfile_ext = ''
  for w in string.gmatch(header_name, '%.%w+') do
    sourcefile_ext = exension_index[w]
    headerfile_ext = w
  end

  if sourcefile_ext == '' or headerfile_ext == '' then
    return nil
  end

  headerfile_ext = '%' .. headerfile_ext
  local source_path = string.gsub(header_name, headerfile_ext, sourcefile_ext)

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
  local fd = fs.fs_open(path, 'a', 438)
  fs.fs_write(fd, content .. '\n\n', 0)
  fs.fs_close(fd)
end

print(attempt_to_change_to_source_dir('/home/haru/repos/'))

return M
