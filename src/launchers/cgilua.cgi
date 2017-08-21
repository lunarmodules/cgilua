#!/usr/bin/env lua

-- CGILua (SAPI) launcher, extracts script to launch
-- either from the command line (use #!cgilua in the script)
-- or from SCRIPT_FILENAME/PATH_TRANSLATED
 
pcall(require, "luarocks.require")
 
local common = require "wsapi.common"
local cgi = require "wsapi.cgi"
 
local cgilua = require "cgilua"

local arg_filename = (...)
 
local response = require "wsapi.response"
local res = response.new()

local function cgi_loader(wsapi_env)
  common.normalize_paths(wsapi_env, arg_filename, "cgilua.cgi")
  return cgilua.main(wsapi_env, res)
end 
 
cgi.run(cgi_loader)