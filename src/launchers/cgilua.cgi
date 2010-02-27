#!/usr/bin/env lua

-- CGILua (SAPI) launcher, extracts script to launch
-- either from the command line (use #!cgilua in the script)
-- or from SCRIPT_FILENAME/PATH_TRANSLATED
 
pcall(require, "luarocks.require")
 
local common = require "wsapi.common"
local cgi = require "wsapi.cgi"
 
local sapi = require "wsapi.sapi"
 
local arg_filename = (...)
 
local function sapi_loader(wsapi_env)
  CGILUA_APPS = wsapi_env.APP_PATH .. "/cgilua"
  CGILUA_CONF = wsapi_env.APP_PATH .. "/cgilua"
  CGILUA_TMP = os.getenv("TMP") or os.getenv("TEMP") or "/tmp"
  CGILUA_ISDIRECT = true
  common.normalize_paths(wsapi_env, arg_filename, "cgilua.cgi")
  return sapi.run(wsapi_env)
end 
 
cgi.run(sapi_loader)
 