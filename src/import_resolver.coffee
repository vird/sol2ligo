m_path = require "path"
fs = require "fs"
{execSync} = require "child_process"

get_folder = (path)->
  list = path.split("/")
  list.pop()
  folder = list.join("/")

url_resolve = (url)->
  # FIX github url's
  # e.g. input https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol
  # e.g. input https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
  # e.g. input https://github.com/OpenZeppelin/openzeppelin-solidity/master/blob/contracts/ownership/Ownable.sol # NOT SUPPORTED by us
  # https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/ownership/Ownable.sol
  if reg_ret = /^https?:\/\/github.com\/([^\/]+)\/([^\/]+)\/(.*)$/.exec url
    [_skip, user, repo, path] = reg_ret
    path_list = path.split "/"
    if path_list[0] == "blob"
      path_list.shift()
    else
      path_list.unshift "master"
    
    path = path_list.join("/")
    url = "https://raw.githubusercontent.com/#{user}/#{repo}/#{path}"
  
  [_skip, pseudo_path] = /^https?:\/\/(.*)/.exec url
  pseudo_path = "import_url_cache/#{pseudo_path}"
  if !fs.existsSync pseudo_path
    folder = get_folder pseudo_path
    # NOTE insecure shell
    execSync "mkdir -p #{folder}"
    execSync "curl #{url} > #{pseudo_path}"
  
  code = fs.readFileSync pseudo_path, "utf-8"
  if /^404: Not Found/.test code
    throw new Error "404. failed to load #{url}"
  return code

module.exports = (path, import_cache = {})->
  is_url = /^https?:\/\/(.*)/.test path
  if !is_url
    path = m_path.resolve path
  return val if (val = import_cache[path])?
  
  folder = get_folder path
  
  if is_url
    code = url_resolve path
  else
    code = fs.readFileSync path, "utf-8"
  
  # HACK WAY
  mk_import = (orig_file)->
    if /^https?:\/\/(.*)/.test orig_file
      file = orig_file
    else if is_url
      [protocol, path_like] = path.split "://"
      folder_like = get_folder path_like
      file_like = folder_like+"/"+orig_file
      file = "#{protocol}://#{file_like}"
    else
      file = m_path.resolve folder+"/"+orig_file
    if import_cache[file]
      """
      // IMPORT RESOLVE #{orig_file}
      // IMPORT SKIP
      """
    else
      code = module.exports file, import_cache
      """
      // IMPORT RESOLVE #{orig_file}
      #{code}
      // IMPORT END
      """
  line_list = code.split("\n")
  for line,idx in line_list
    line = line.trim()
    if reg_ret = /^import\s+\{.*\}\s+from\s+\"(.+)\";?$/.exec line
      [_skip, orig_file] = reg_ret
      line_list[idx] = mk_import orig_file
    else if reg_ret = /^import\s+\"(.+)\";?$/.exec line
      [_skip, orig_file] = reg_ret
      line_list[idx] = mk_import orig_file
    else if reg_ret = /^import\s+\'(.+)\';?$/.exec line
      [_skip, orig_file] = reg_ret
      line_list[idx] = mk_import orig_file
  
  # split/join because we inserted multiline text
  code = line_list.join("\n")
  # deduplicate pragma
  line_list = code.split("\n")
  pragma_hash = {}
  filter_line_list = []
  for line in line_list
    key = line.trim()
    if /^pragma/.test key
      continue if pragma_hash.hasOwnProperty key
      pragma_hash[key] = true
    filter_line_list.push line
  
  code = filter_line_list.join("\n")
  
  # code = code.replace(/pragma experimental .*/g, "")
  code = code.replace(/pragma experimental "v0.5.0";?/g, "")
  import_cache[path] = code
