----------------------------------------------------------------------------
-- Session library.
----------------------------------------------------------------------------
-- $Id: session.lua,v 1.3 2004/07/22 23:41:24 tomas Exp $
----------------------------------------------------------------------------

require"luafilesystem"

local Public = {}
session = Public
setmetatable (Public, {
	__index = function (t,n) error("Error reading undefined variable "..n, 2) end,
})

local assert, loadfile, pairs, type = assert, loadfile, pairs, type
local format, strfind, strrep, strsub = string.format, string.find, string.rep, string.sub
local open, write = io.open, io.write
local remove = os.remove
local dir = luafilesystem.dir

-- Internal state variables.
local root_dir = "/Users/tomas/tmp/"
local counter = 0

setfenv (1, Public)

----------------------------------------------------------------------------
-- Serializes a session table.
-- @param tab Table representing the session.
-- @param outf Function used to generate the output.
----------------------------------------------------------------------------
local function serialize_table (tab, outf)
	outf ("{")
	for i, v in pairs (tab) do
		-- serialize the key
		outf ("[")
		local t = type(i)
		if t == "number" or t == "boolean" then
			outf (i)
		elseif t == "string" then
			outf (format ("%q", i))
		end
		outf ("]")

		outf ("=")
		-- serialize the value
		local t = type (v)
		local val, fmt
		if t == "string" then
			fmt = "%q,"
			val = v
		elseif t == "number" then
			fmt = "%d,"
			val = v
		elseif t == "boolean" then
			fmt = v and "true," or "false,"
		elseif t == "table" then
			fmt = ","
			val = ""
			serialize_table (v, outf)
		end
		outf (format (fmt, val))
	end
	outf ("}\n")
end

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
	local fh = assert (open (filename (id), "w+"))
	fh:write "return "
	serialize_table (data, function (s) fh:write(s) end)
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
