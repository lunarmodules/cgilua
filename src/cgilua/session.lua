----------------------------------------------------------------------------
-- Session library.
----------------------------------------------------------------------------
-- $Id: session.lua,v 1.7 2004/11/22 19:49:23 tomas Exp $
----------------------------------------------------------------------------

require"lfs"
require"cgilua.serialize"

local assert, loadfile, pairs, type = assert, loadfile, pairs, type
local format, strfind, strrep, strsub = string.format, string.find, string.rep, string.sub
local _open = io.open
local remove = os.remove
local dir = lfs.dir

-- Internal state variables.
local root_dir = nil
local counter = 0

module (arg and arg[1])

----------------------------------------------------------------------------
-- Creates a new identifier.
----------------------------------------------------------------------------
local function new_id ()
	counter = counter + 1
	return format ("%08d", counter)
end

----------------------------------------------------------------------------
-- Checks identifier format.
----------------------------------------------------------------------------
local function check_id (id)
	return (strfind (id, strrep ("%d", 8)) ~= nil)
end

----------------------------------------------------------------------------
-- Produces a file name based on a session.
-- @param id Session identification.
-- @return String with the session file name.
----------------------------------------------------------------------------
local function filename (id)
	return root_dir..id..".lua"
end

----------------------------------------------------------------------------
-- Deletes a session.
-- @param id Session identification.
----------------------------------------------------------------------------
function delete (id)
	assert (check_id (id))
	remove (filename (id))
end

----------------------------------------------------------------------------
-- Creates a new session identifier.
-- @return Session identification.
----------------------------------------------------------------------------
function new ()
	local files = {}
	if not lfs.attributes (root_dir) then
		assert (lfs.mkdir (root_dir))
	end
	for f in dir (root_dir) do
		files[f] = true
	end
	local id = new_id ()
	while files[id..".lua"] do
		id = new_id ()
	end
	return id
end

----------------------------------------------------------------------------
-- Loads data from a session.
-- @param id Session identification.
-- @return Table with session data.
----------------------------------------------------------------------------
function load (id)
	assert (check_id (id))
	local f, err = loadfile (filename (id))
	if not f then
		return nil, err
	else
		return f()
	end
end

----------------------------------------------------------------------------
-- Saves data to a session.
-- @param id Session identification.
-- @param data Table with session data to be saved.
----------------------------------------------------------------------------
function save (id, data)
	assert (check_id (id))
	local fh = assert (_open (filename (id), "w+"))
	fh:write "return "
	cgilua.serialize (data, function (s) fh:write(s) end)
	fh:close()
end

----------------------------------------------------------------------------
-- Changes the session directory.
-- @param path String with the new session directory.
----------------------------------------------------------------------------
function setsessiondir (path)
	if strsub (path, -2, -2) ~= '/' then
		path = path..'/'
	end
	root_dir = path
end

----------------------------------------------------------------------------
local ID_NAME = "cgilua session identification"
local id = nil

----------------------------------------------------------------------------
-- Open user session.
-- This function should be called before the script is executed.
----------------------------------------------------------------------------
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

----------------------------------------------------------------------------
-- Close user session.
-- This function should be called after the script is executed.
----------------------------------------------------------------------------
function close ()
	if next (cgilua.data) then
		cgilua.session.save (id, cgilua.data)
		id = nil
	end
end
