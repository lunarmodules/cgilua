require"cgilua.session"

local _G = _G
module (arg and arg[1])

local ID_NAME = "cgilua session identification"
local id = nil

function open ()
	local mkurlpath = cgilua.mkurlpath
	function _G.cgilua.mkurlpath (script, data)
		if not data then
			data = {}
		end
		data[ID_NAME] = id
		return mkurlpath (script, data)
	end

	id = cgi[ID_NAME] or cgilua.session.new()
	if id then
		_G.cgi[ID_NAME] = nil
		_G.cgilua.data = cgilua.session.load (id) or {}
	end
end

function close ()
	if next (cgilua.data) then
		cgilua.session.save (id, cgilua.data)
		id = nil
	end
end
