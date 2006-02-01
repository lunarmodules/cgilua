----------------------------------------------------------------------------
-- Session library.
----------------------------------------------------------------------------
-- $Id: session.lua,v 1.14 2006/02/01 13:46:37 tomas Exp $
----------------------------------------------------------------------------

local lfs = require"lfs"
local serialize = require"cgilua.serialize"

local assert, ipairs, _G, loadfile, next, tonumber, type = assert, ipairs, _G, loadfile, next, tonumber, type
local format, gsub, strfind, strsub = string.format, string.gsub, string.find, string.sub
local tinsert = table.insert
local _open = io.open
local date, remove = os.date, os.remove
local rand, randseed = math.random, math.randomseed
local attributes, dir, mkdir = lfs.attributes, lfs.dir, lfs.mkdir

module (arg and arg[1])

----------------------------------------------------------------------------
-- Internal state variables.
local root_dir = nil
local timeout = 10 * 60 -- 10 minutes

--
-- Checks identifier's format.
--
local function check_id (id)
	return (strfind (id, "^%d+$") ~= nil)
end

--
-- Produces a file name based on a session.
-- @param id Session identification.
-- @return String with the session file name.
--
local function filename (id)
	return format ("%s/%s.lua", root_dir, id)
end

----------------------------------------------------------------------------
-- Deletes a session.
-- @param id Session identification.
----------------------------------------------------------------------------
function delete (id)
	assert (check_id (id))
	remove (filename (id))
end

--
-- Searches for a file in the root_dir
--
local function find (file)
	for f in dir (root_dir) do
		if f == file then
			return true
		end
	end
	return false
end

--
-- Creates a new identifier.
-- @param last_id Last session identifier
-- @return New identifier.
--
local seed = false
local function new_id (last_id)
	if seed then
		randseed (date"%S" * last_id)
		seed = false
	else
		seed = true
	end
	return gsub (rand (), "%D", "")
end

----------------------------------------------------------------------------
-- Creates a new session identifier.
-- @return Session identification.
----------------------------------------------------------------------------
function new ()
	local files = {}
	if not attributes (root_dir) then
		assert (mkdir (root_dir))
	end
	local id = new_id ()
	while find (id..".lua") do
		id = new_id (id)
	end
	return id
end

----------------------------------------------------------------------------
-- Changes the session identificator generator.
-- @param func Function.
----------------------------------------------------------------------------
function setidgenerator (func)
	if type (func) == "function" then
		new_id = func
	end
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
	serialize (data, function (s) fh:write(s) end)
	fh:close()
end

----------------------------------------------------------------------------
-- Removes expired sessions.
----------------------------------------------------------------------------
function cleanup ()
	local rem = {}
	local now = tonumber (date ("%s"))
	for file in dir (root_dir) do
		local attr = attributes(root_dir.."/"..file)
		if attr and attr.mode == 'file' then
			if attr.modification + timeout < now then
				tinsert (rem, file)
			end
		end
	end
	for _, file in ipairs (rem) do
		remove (root_dir.."/"..file)
	end
end

----------------------------------------------------------------------------
-- Changes the session timeout.
-- @param t Number of seconds to maintain a session.
----------------------------------------------------------------------------
function setsessiontimeout (t)
	if type (t) == "number" then
		timeout = t
	end
end

----------------------------------------------------------------------------
-- Changes the session directory.
-- @param path String with the new session directory.
----------------------------------------------------------------------------
function setsessiondir (path)
	root_dir = gsub (path, "[/\\]$", "")
end

----------------------------------------------------------------------------
local ID_NAME = "cgilua session identification"
local id = nil

----------------------------------------------------------------------------
-- Open user session.
-- This function should be called before the script is executed.
----------------------------------------------------------------------------
function open ()
	local mkurlpath = _G.cgilua.mkurlpath
	function _G.cgilua.mkurlpath (script, data)
		if not data then
			data = {}
		end
		data[ID_NAME] = id
		return mkurlpath (script, data)
	end
	cleanup()

	id = _G.cgi[ID_NAME] or new()
	if id then
		_G.cgi[ID_NAME] = nil
		_G.cgilua.session.data = load (id) or {}
	end
end

----------------------------------------------------------------------------
-- Close user session.
-- This function should be called after the script is executed.
----------------------------------------------------------------------------
function close ()
	if next (_G.cgilua.session.data) then
		save (id, _G.cgilua.session.data)
		id = nil
	end
end
