-- Session library
-- Fields of table cgilua.session will persist througout the session
--[[
require"cgilua.session"
require"cgilua.cl_ses"
cgilua.session.setsessiondir ("/tmp/cgilua")
cgilua.addopenfunction (cgilua.cl_ses.open)
cgilua.addclosefunction (cgilua.cl_ses.close)
--]]

-- Emulating old behavior loading file "env.lua" from the script's directory
--[[
cgilua.addopenfunction (function ()
	assert (loadfile ("env.lua")) ()
end)
--]]
