----------------------------------------------------------------------------
-- Serialize tables.
-- It works only for tables without cycles and without functions or
-- userdata inside it.
-- $Id: serialize.lua,v 1.1 2004/08/30 10:59:01 tomas Exp $
----------------------------------------------------------------------------

local ipairs, pairs, type = ipairs, pairs, type
local format = string.format
local sort, tinsert = table.sort, table.insert
local max, min = math.max, math.min

package ("serialize", arg and arg[1])

serialize_value = nil

----------------------------------------------------------------------------
-- Serializes a table.
-- @param tab Table representing the session.
-- @param outf Function used to generate the output.
----------------------------------------------------------------------------
function serialize_table (tab, outf)
	outf ("{")
	-- prepare list of keys
	local keys = { boolean = {}, number = {}, string = {} }
	local min, max = 1, 0
	for key in pairs (tab) do
		local t = type(key)
		if t == "string" then
			tinsert (keys.string, key)
		else
			keys[t][key] = true
		end
	end
	-- serialize entries with numeric keys
	local n = keys.number
	for key, val in ipairs (tab) do
		serialize_value (val, outf)
		n[key] = nil
	end
	for key in pairs (n) do
		outf ("[")
		outf (key)
		outf ("] = ")
		serialize_value (tab[key], outf)
	end
	-- serialize entries with boolean keys
	local tr = keys.boolean[true]
	if tr then
		outf (format ("[%s] = ", tostring(tr)))
		serialize_value (tab[tr], outf)
	end
	local fa = keys.boolean[false]
	if fa then
		outf (format ("[%s] = ", tostring(fa)))
		serialize_value (tab[fa], outf)
	end
	-- serialize entries with string keys
	sort (keys.string)
	for _, key in ipairs (keys.string) do
		outf ("[")
		outf (format ("%q", key))
		outf ("] = ")
		serialize_value (tab[key], outf)
	end
	outf ("}\n")
end


----------------------------------------------------------------------------
-- Serialize a value.
----------------------------------------------------------------------------
serialize_value = function (v, outf)
	local t = type (v)
	local fmt, val
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
		--val = ""
		serialize_table (v, outf)
	else
		fmt = "%q,"
		val = tostring (v)
	end
	outf (format (fmt, val))
end
