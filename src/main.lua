---------------------------------------------------------------------
-- Main Lua script.
-- This script does not depend on the launcher, only on the
-- basic API.
-- $Id: main.lua,v 1.6 2004/08/04 12:17:49 tomas Exp $
---------------------------------------------------------------------

local cgilua_conf = CGILuaRoot().."/conf/cgilua.conf"
local cgilua_libdir = CGILuaRoot().."/lib/cgilua"

-- Loading required libraries
LUA_PATH = cgilua_libdir.."/?.lua;"..cgilua_libdir.."/?"
require"cgilua"

-- Loading/executing configuration file
cgilua.pcall (cgilua.doif, cgilua_conf)
-- Cleaning environment
cgilua.removeglobals {
	"os.execute",
	"loadlib",
	"cgilua.setlibdir",
}
-- Defining directory variables and building `cgi' table
cgi = {}
cgilua.pcall (cgilua.getparams, cgi)
-- Changing current directory to the script's "physical" dir
local curr_dir = lfs.currentdir()
cgilua.pcall (lfs.chdir, cgilua.script_pdir)
-- Opening function
cgilua.pcall (cgilua.open)
-- Executing script
local result = cgilua.pack (cgilua.pcall (cgilua.handle, cgilua.script_file))
-- Closing function
cgilua.pcall (cgilua.close)
-- Cleanup
cgilua.reset ()
-- Changing to original directory
cgilua.pcall (lfs.chdir, curr_dir)
-- Returning results to server
table.remove (result, 1)
return unpack (result)
