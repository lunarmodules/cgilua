cl_ses = {}

local ID = "cl_session.identification"

function cl_ses.open ()
	local mkurlpath = cgilua.mkurlpath
	function cgilua.mkurlpath (script, data)
		if not data then
			data = {}
		end
		data[ID] = cl_ses.id
		return mkurlpath (script, data)
	end

	local id = cgi[ID] or session.new()
	if id then
		cgi[ID] = nil
		cgilua.session = session.load (id) or {}
		cl_ses.id = id
	--else
		--cgilua.session = {}
	end
end

function cl_ses.close ()
	if next (cgilua.session) then
		session.save (cl_ses.id, cgilua.session)
		cl_ses.id = nil
	end
end
