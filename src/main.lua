---------------------------------------------------------------------
-- Main Lua script.
-- This script does not depend on the launcher, only on the
-- basic API.
-- $Id: main.lua,v 1.5 2004/07/29 15:02:49 tomas Exp $
---------------------------------------------------------------------

local cgilua_conf = CGILuaRoot().."/conf/cgilua.conf"
local cgilua_libdir = CGILuaRoot().."/lib/cgilua"

---------------------------------------------------------------------
-- Loading required libraries
---------------------------------------------------------------------
LUA_PATH = cgilua_libdir.."/?.lua;"..cgilua_libdir.."/?"
require"cgilua"

---------------------------------------------------------------------
-- Cleaning environment
---------------------------------------------------------------------
cgilua.removeglobals {
	"os.execute",
	"loadlib",
}

---------------------------------------------------------------------
-- Executing requested script
---------------------------------------------------------------------
-- Loading configuration file
cgilua.pcall (cgilua.doif, cgilua_conf)
-- Define directory variables and build `cgi' table.
cgi = {}
cgilua.pcall (cgilua.getparams, cgi)
-- Changing current directory to the script's "physical" dir
local curr_dir = lfs.currentdir()
cgilua.pcall (lfs.chdir, cgilua.script_pdir)
-- Opening function
cgilua.pcall (cgilua._open)
-- Executing script
local result = { cgilua.pcall (cgilua.handle, cgilua.script_file) }
-- Closing function
cgilua.pcall (cgilua.close)
-- Cleanup
cgilua.reset ()
cgilua.pcall (lfs.chdir, curr_dir)

table.remove (result, 1)
return unpack (result)