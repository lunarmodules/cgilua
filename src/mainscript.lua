----------------------------------------------------------------------------
-- $Id: mainscript.lua,v 1.4 2003/04/28 10:49:48 tomas Exp $
--
-- CGILua "main" script
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- CGILua Libraries configuration
----------------------------------------------------------------------------

-- Redefine require e loadlib
local original_lib_dir = lib_dir
local original_loadlib = loadlib
_G.loadlib = nil
local nova_loadlib = function (packagename, funcname)
	return original_loadlib (original_lib_dir..packagename, funcname)
end
local original_require = require
_G.require = function (packagename)
	-- packagename cannot contain some special punctuation characters.
	assert (not (string.find (packagename, "[^%P%.%-]") or
			string.find (packagename, "%.%.")),
		"Package name cannot contain punctuation characters")

	_G.loadlib = nova_loadlib
	_G.LUA_PATH = original_lib_dir.."?.lua"
	original_require (packagename)
	_G.loadlib = nil
end

----------------------------------------------------------------------------
-- Load auxiliar functions defined in CGILua namespace (cgilua)
----------------------------------------------------------------------------
local f_aux, err = loadfile (main_dir.."prep.lua")
assert (f_aux, err)
f_aux ()
local f_aux, err = loadfile (main_dir.."auxiliar.lua")
assert (f_aux, err)
f_aux ()

----------------------------------------------------------------------------
-- CGILua "security" configuration
---------------------------------------------------------------------------
--
-- copy 'map' information to CGILua namespace
--
cgilua.script_path = script_path

--
-- remove globals not to be accessed by CGILua scripts
-- 
cgilua.removeglobals{
	-- functions to be removed from the environment
	"execute",
}

--
-- Maximum "total" input size allowed (in bytes)
--
-- (total size of the incoming request data as defined by 
--    the metavariable CONTENT_LENGTH)
cgilua.setmaxinput(1024 * 1024) -- 1 MB

--
-- Maximum size for file upload (in bytes)
--   (can be redefined by 'env.lua' or a script,
--    but 'maxinput' is always checked first)
--
cgilua.setmaxfilesize(500 * 1024) -- 500 KB

----------------------------------------------------------------------------
-- Configure CGILua environment and execute the script
----------------------------------------------------------------------------

-- get the 'physical' directory of the script
cgilua.script_pdir = cgilua.splitpath(cgilua.script_path)

-- check if CGILua handles this script type
local handler = cgilua.getscripthandler (cgilua.script_path)
if not handler then
	local path_info = os.getenv("PATH_INFO")
	if not path_info then
		error ("No script")
	end
	cgilua.redirect(cgilua.mkabsoluteurl(path_info))
else
	-- get the 'virtual' path of the script (PATH_INFO)
	cgilua.script_vpath = os.getenv("PATH_INFO")

	-- get the 'virtual' directory of the script
	--  (used to create URLs to scripts in the same 'virtual' directory)
	cgilua.script_vdir = cgilua.splitpath(os.getenv("PATH_INFO"))

	-- save the URL path to cgilua
	cgilua.urlpath = os.getenv("SCRIPT_NAME")

	-- change current directory to the script's "physical" dir
	dir.chdir(cgilua.script_pdir)

	-- set the script environment
	cgilua.doenv(cgilua.script_pdir.."env.lua")

	-- parse the incoming request data
	cgi = {}
	if os.getenv("REQUEST_METHOD") == "POST" then
		cgilua.parsepostdata(cgi)
	end
	cgilua.parsequery(os.getenv("QUERY_STRING"),cgi)

	handler (cgilua.script_path)
	cgilua.close()				-- "close" function
end

