-- Emulating old behavior loading file "env.lua" from the script's directory
--[[
cgilua.addopenfunction (function ()
	cgilua.doif ("env.lua")
end)
--]]

-- Basic configuration for using sessions
--[[
require"cgilua.session"
cgilua.session.setsessiondir ("/tmp/")
-- The following function must be called by every script that needs session.
function cgilua.enablesession ()
	cgilua.session.open ()
	cgilua.addclosefunction (cgilua.session.close)
end
--]]

-- Compatibility
cgilua.preprocess = cgilua.handlelp
cgilua.includehtml = cgilua.lp.include

-- Directories for specific applications libraries.
-- The following table should be indexed by the virtual path of the application.
local app_lib_dir = {
}
local package = package
cgilua.addopenfunction (function ()
	local app = app_lib_dir[cgilua.script_vdir]
	if app then
		package.path = package.path..';'..app..'/?.lua'
	end
end)
