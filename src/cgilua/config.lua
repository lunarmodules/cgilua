-- CGILua configuration file
-- $Id: config.lua,v 1.13 2007/09/25 23:25:17 carregal Exp $

-- Emulating old behavior loading file "env.lua" from the script's directory
--[[
cgilua.addopenfunction (function ()
	cgilua.doif ("env.lua")
end)
--]]

-- Optional backward compatibility with the global cgi table
-- cgi = cgilua.CGI

-- Basic configuration for using sessions
-- require"cgilua.session"
-- cgilua.session.setsessiondir (CGILUA_TMP)
-- Add cgilua.enablesession() at the beginning of every script which depends
-- on sessions.

-- Compatibility

cgilua.preprocess = cgilua.handlelp
cgilua.includehtml = cgilua.lp.include

-- Directories for applications' libraries.
-- The following table should be indexed by the virtual path of the application
-- and contain the absolute path of the application's Lua-library directory.
--[[
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
--]]