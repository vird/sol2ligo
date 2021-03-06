require "fy"
fs = require "fs"
setupMethods = require "solc/wrapper"
{execSync} = require "child_process"

solc_hash = {}

module.exports = (code, opt={})->
  {
    solc_version
    suggest_solc_version
    auto_version
    debug
    allow_download
  } = opt
  allow_download ?= true
  
  target_dir = "#{__dirname}/../solc-bin/bin"
  if allow_download and !fs.existsSync "#{target_dir}/list.js"
    perr "download solc catalog"
    execSync "mkdir -p #{target_dir}"
    execSync "curl https://raw.githubusercontent.com/ethereum/solc-bin/gh-pages/bin/list.js --output #{target_dir}/list.js"
  
  release_hash = require("../solc-bin/bin/list.js").releases
  
  solc_full_name = null
  auto_version ?= true
  
  pick_version = (candidate_version)->
    if debug
      perr "try pick_version #{candidate_version}" # DEBUG
    if full_name = release_hash[candidate_version]
      solc_full_name = full_name
    else
      perr "unknown release version of solc #{candidate_version}; will take latest"
  
  if auto_version and !solc_version?
    # HACKY WAY
    strings = code.trim().split("\n")
    for str in strings
      header = str.trim()
      if reg_ret = /^pragma solidity \^?([.0-9]+);/.exec header
        pick_version reg_ret[1]
        break
      else if reg_ret = /^pragma solidity >=([.0-9]+)/.exec header
        pick_version reg_ret[1]
        break
  else if solc_version
    pick_version solc_version
  
  if !solc_full_name and suggest_solc_version
    pick_version suggest_solc_version
  
  solc_full_name ?= "soljson-latest.js"
  
  if !(solc = solc_hash[solc_full_name])?
    path = "#{target_dir}/#{solc_full_name}"
    if allow_download and !fs.existsSync path
      perr "download #{solc_full_name}"
      execSync "curl https://raw.githubusercontent.com/ethereum/solc-bin/gh-pages/bin/#{solc_full_name} --output #{target_dir}/#{solc_full_name}"
      
    perr "loading solc #{solc_full_name}"
    solc_hash[solc_full_name] = solc = setupMethods require path
  
  if debug
    perr "use #{solc_full_name}" # DEBUG
  input = {
    language: "Solidity",
    sources: {
      "test.sol": {
        content: code
      }
    },
    settings: {
      
      outputSelection: {
        "*": {
          "*": [ "*" ]
          "" : ["ast"]
        }
      }
    }
  }
  
  output = JSON.parse(solc.compile(JSON.stringify(input)))
  
  is_ok = true
  for error in output.errors or []
    if error.type == "Warning"
      unless opt.silent
        perr "WARNING", error
      continue
    is_ok = false
    perr error
  
  if !is_ok
    err = new Error "solc compiler error"
    err.__inject_error_list = output.errors
    throw err

  res = output.sources["test.sol"].ast
  if !res
    ### !pragma coverage-skip-block ###
    throw new Error "!res"
  res
