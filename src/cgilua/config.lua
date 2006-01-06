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
cgilua.addopenfunction (cgilua.session.open)
cgilua.addclosefunction (cgilua.session.close)
--]]

-- Compatibility
cgilua.preprocess = cgilua.handlelp
cgilua.includehtml = cgilua.lp.include
