-- CGILua configuration file
-- $Id: config.lua,v 1.9 2006/12/13 13:12:38 tomas Exp $

-- Emulating old behavior loading file "env.lua" from the script's directory
--[[
cgilua.addopenfunction (function ()
	cgilua.doif ("env.lua")
end)
--]]

-- Basic configuration for using sessions
require"cgilua.session"
cgilua.session.setsessiondir ("/tmp/")
-- The following function must be called by every script that needs session.
local already_enabled = false
function cgilua.enablesession ()
	if already_enabled then
		return
	else
		already_enabled = true
	end
	cgilua.session.open ()
	cgilua.addclosefunction (cgilua.session.close)
end

-- Compatibility
cgilua.preprocess = cgilua.handlelp
cgilua.includehtml = cgilua.lp.include

-- Directories for specific applications' libraries.
-- The following table should be indexed by the virtual path of the application
-- and contain the absolute path of the application's Lua-library directory.
local app_lib_dir = {
	["/t/"] = "/usr/local/src/cgilua/tests",
}
local package = package
cgilua.addopenfunction (function ()
	local app = app_lib_dir[cgilua.script_vdir]
	if app then
		package.path = app.."/?.lua;"..package.path
	end
end)
