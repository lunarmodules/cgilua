---------------------------------------------------------------------
-- Main Lua script.
-- This script does not depend on the launcher, only on the
-- basic API.
-- $Id: t_main.lua,v 1.1 2004/03/25 19:01:39 tomas Exp $
---------------------------------------------------------------------

local cgilua_conf = "CGILUA_CONF"
local cgilua_libdir = "CGILUA_LIBDIR"

---------------------------------------------------------------------
-- Loading required libraries
---------------------------------------------------------------------
LUA_PATH = cgilua_libdir.."/?;"..cgilua_libdir.."/?.lua"
require"dir"
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
cgilua.getparams (cgi)

-- Loading application script (is this really necessary?)
cgilua.pcall (cgilua.doif, appscript)
-- Changing current directory to the script's "physical" dir
dir.chdir (cgilua.script_pdir)
-- Loading script environment
cgilua.pcall (cgilua.doif, userscriptname)
-- Executing script
cgilua.pcall (cgilua.handle, cgilua.script_file)
-- Closing function
cgilua.close ()
-- Cleanup
cgilua.reset ()
