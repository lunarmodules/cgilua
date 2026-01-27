------------------------------------------------------------------------------
-- Session library.
------------------------------------------------------------------------------

local cgilua = require"cgilua"
local cookies = require"cgilua.cookies"
local lfs = require"lfs"
local serialize = require"cgilua.serialize".serialize

local assert, ipairs, loadfile, type = assert, ipairs, loadfile, type
local strbyte, strformat, strrep = string.byte, string.format, string.rep
local tinsert = table.insert
local ioopen = io.open
local osremove, ostime = os.remove, os.time
local lfs_attributes, lfs_dir = lfs.attributes, lfs.dir

local INVALID_SESSION_ID = "Invalid session identification"

local M = {
	_VERSION = "2.0",

	data = nil, -- will be created when a session is created
	already_enabled = false,
	base_dir = "/tmp", -- no '/' at the end
	--id_pattern = "^"..strrep ("[0-9A-F]", 32)..strrep ("%d", 12).."$",
	id_pattern = "^"..strrep ("[0-9A-F]", 32),
	timeout = 10 * 60, -- 10 min
	token_name = "cgilua_session_identification",
	token_options = { -- lower-case options
		path = "/", -- site-wide coverage
		samesite = "Lax", -- "None" and "Strict" are the other valid values
		httponly = true, -- forbids JavaScript access to cookie
	},
}

------------------------------------------------------------------------------
-- Removes expired sessions.
------------------------------------------------------------------------------
function M.cleanup ()
	local rem = {} -- array of files to be deleted
	local now = ostime ()
	for file in lfs_dir (M.base_dir) do
		local attr = lfs_attributes(M.base_dir.."/"..file)
		if attr and attr.mode == 'file' then
			if attr.modification + M.timeout < now then
				-- Delay removal to avoid problems during directory traversal
				tinsert (rem, file)
			end
		end
	end
	-- Delete data from expired sessions
	for _, file in ipairs (rem) do
		osremove (M.base_dir.."/"..file)
	end
end

------------------------------------------------------------------------------
-- Creates a new identifier.
-- @return String with a new identifier.
------------------------------------------------------------------------------
function M.new_id ()
	local remote_ip = ''
--[=[
		(cgilua.servervariable"REMOTE_ADDR"..".")
		:gsub ("(%d+)%.", function (num)
			local n = #num
			return strrep ("0", 3-n)..num
		end)
--]=]
	-- Random number
	local fh = assert (ioopen ("/dev/urandom", "rb"))
	local binstr = fh:read(16)
	fh:close()
	-- Convert each byte to hex
	local hexnum = binstr:gsub ("(.)", function (c)
		return strformat ("%02X", strbyte (c))
	end)
	return hexnum..remote_ip
end

------------------------------------------------------------------------------
-- Checks identifier's format.
-- @param id Session identifier candidate.
-- @return Boolean indicating wether the identifier is valid.
------------------------------------------------------------------------------
function M.check_id (id)
	return id and (id:match (M.id_pattern) ~= nil)
end

------------------------------------------------------------------------------
-- Produces a file name based on a session identifier.
-- @param id Session identifier.
-- @return String with the session file name.
------------------------------------------------------------------------------
function M.filename (id)
	return strformat ("%s/%s.lua", M.base_dir, id)
end

------------------------------------------------------------------------------
-- Searches for a file in the base_dir.
-- @param id Session identifier candidate.
-- @return Boolean indicating wether the file was found.
------------------------------------------------------------------------------
function M.find_file (id)
	local fh = ioopen (M.filename (id))
	if fh then
		fh:close ()
		return true
	else
		return false
	end
end

------------------------------------------------------------------------------
-- Deletes a session.
-- @param id Session identifier.
------------------------------------------------------------------------------
function M.delete (id)
	id = id or M.id
	if not M.check_id (id) then
		return nil, INVALID_SESSION_ID
	end
	osremove (M.filename (id))
end

------------------------------------------------------------------------------
-- Loads data from a session.
-- @return Table with session data or nil in case of error.
-- @return In case of error, also returns the error message.
------------------------------------------------------------------------------
function M.load ()
	if not M.check_id (M.id) then
		return nil, INVALID_SESSION_ID
	end
	local f, err = loadfile (M.filename (M.id))
	if not f then
		return nil, err
	else
		return f()
	end
end

------------------------------------------------------------------------------
-- Saves data to a file.
-- @param id Session identification.
-- @param data Table with session data to be saved.
------------------------------------------------------------------------------
function M.save (id, data)
	if M.id and type(M.data) == "table" then
		if not M.check_id (M.id) then
			return nil, INVALID_SESSION_ID
		end
		local fh = assert (ioopen (M.filename (M.id), "w+"))
		fh:write "return "
		serialize (data, function (s) fh:write(s) end)
		fh:close()
	end
end

------------------------------------------------------------------------------
-- User API
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Creates a new session and returns its identifier.
-- @return Session identification.
------------------------------------------------------------------------------
function M.new ()
	if M.id then
		M.destroy () -- erases M.id and session data
	end
	local id
	-- Make sure there is no other session with the same identifier
	repeat
		id = M.new_id ()
	until not M.find_file (id)
	M.id = id
	M.data = {}
	M.save ()
	cookies.set (M.token_name, id, M.token_options)
	return id
end

------------------------------------------------------------------------------
-- Destroys the session, erasing its data.
------------------------------------------------------------------------------
function M.destroy ()
	M.data = nil
	M.delete (M.id)
	M.id = nil
end

------------------------------------------------------------------------------
-- Destroy the session and delete the cookie.
------------------------------------------------------------------------------
function M.logout ()
	M.destroy ()
	cookies.delete (M.token_name, M.token_options)
end

------------------------------------------------------------------------------
-- Open a specific user session passed as parameter.
------------------------------------------------------------------------------
function M.force_open (id)
	if not id or not M.check_id (id) then
		return false
	end

	-- try to load session data persisted from last request!
	M.id = id
	M.data = M.load (id)
	cookies.set (M.token_name, id, M.token_options)
	return true
end

------------------------------------------------------------------------------
-- Prepare session environment:
-- 1. clean up older sessions
-- 2. if there is a session-id, try to open the session;
-- 3. set the close-function that will persist the session-data.
--
-- Note that this function DOES NOT automatically opens a session if there
-- is no session-id.  In other words, one have to create a new session in
-- this case (supposedly checking login identification and password before).
------------------------------------------------------------------------------
M.cleanup ()

local id = M.cookies.get (M.token_name)
if id and M.check_id (id) and M.find_file (id) then
	-- try to load session data persisted from last request!
	M.id = id
	M.data = M.load ()
end
cgilua.addclosefunction (M.save)

------------------------------------------------------------------------------
return M
