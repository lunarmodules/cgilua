-- Session library
-- Fields of table cgilua.session will persist througout the session
--[[
require"cgilua.session"
cgilua.session.setsessiondir ("/tmp/cgilua")
cgilua.addopenfunction (cgilua.session.open)
cgilua.addclosefunction (cgilua.session.close)
--]]

-- Emulating old behavior loading file "env.lua" from the script's directory
--[[
cgilua.addopenfunction (function ()
	cgilua.doif ("env.lua")
end)
--]]
