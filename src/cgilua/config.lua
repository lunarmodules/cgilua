-- CGILua configuration file
-- $Id: config.lua,v 1.10 2007/07/19 20:07:40 tomas Exp $

-- Emulating old behavior loading file "env.lua" from the script's directory
--[[
cgilua.addopenfunction (function ()
	cgilua.doif ("env.lua")
end)
--]]

-- Basic configuration for using sessions
require"cgilua.session"
cgilua.session.setsessiondir ("/tmp/cgilua/")
-- Add cgilua.enablesession() at the beginning of every script which depends
-- on sessions.

-- Compatibility
cgilua.preprocess = cgilua.handlelp
cgilua.includehtml = cgilua.lp.include

-- Directories for applications' libraries.
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
