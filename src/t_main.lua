---------------------------------------------------------------------
-- Main Lua script.
-- This script does not depend on the launcher, only on the
-- basic API.
-- $Id: t_main.lua,v 1.3 2004/04/16 10:17:36 tomas Exp $
---------------------------------------------------------------------

local cgilua_root = "CGILUA_DIR"
local cgilua_conf = cgilua_root.."/conf/cgilua.conf"
local cgilua_libdir = cgilua_root.."/lib"

---------------------------------------------------------------------
-- Loading required libraries
---------------------------------------------------------------------
LUA_PATH = cgilua_libdir.."/?.lua;"..cgilua_libdir.."/?"
require"dir"
require"cookies"
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

-- Loading application script (is this really necessary?)
cgilua.pcall (cgilua.doif, appscript)
-- Changing current directory to the script's "physical" dir
cgilua.pcall (dir.chdir, cgilua.script_pdir)
-- Loading script environment
cgilua.pcall (cgilua.doif, userscriptname)
-- Executing script
cgilua.pcall (cgilua.handle, cgilua.script_file)
-- Closing function
cgilua.close ()
-- Cleanup
cgilua.reset ()
