---------------------------------------------------------------------
-- Main Lua script.
-- This script does not depend on the launcher, only on the
-- basic API.
-- $Id: t_main.lua,v 1.9 2004/07/19 19:30:20 tomas Exp $
---------------------------------------------------------------------

local cgilua_root = "CGILUA_DIR"
local cgilua_conf = cgilua_root.."/conf/cgilua.conf"
local cgilua_libdir = cgilua_root.."/lib/cgilua"

---------------------------------------------------------------------
-- Loading required libraries
---------------------------------------------------------------------
LUA_PATH = cgilua_libdir.."/?.lua;"..cgilua_libdir.."/?"
require"luafilesystem"
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
local curr_dir = luafilesystem.currentdir()
cgilua.pcall (luafilesystem.chdir, cgilua.script_pdir)
-- Opening function
cgilua.pcall (cgilua._open)
-- Executing script
local result = { cgilua.pcall (cgilua.handle, cgilua.script_file) }
-- Closing function
cgilua.pcall (cgilua.close)
-- Cleanup
cgilua.reset ()
cgilua.pcall (luafilesystem.chdir, curr_dir)

table.remove (result, 1)
return unpack (result)
