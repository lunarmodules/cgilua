----------------------------------------------------------------------------
-- $Id: urlcode.lua,v 1.1 2004/08/27 15:50:33 tomas Exp $
----------------------------------------------------------------------------

local next, tonumber, type = next, tonumber, type
local string = string

package("urlcode", arg and arg[1])

----------------------------------------------------------------------------
-- Decode an URL-encoded string (see RFC 2396)
----------------------------------------------------------------------------
function unescape (str)
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

----------------------------------------------------------------------------
-- URL-encode a string (see RFC 2396)
----------------------------------------------------------------------------
function escape (str)
	str = string.gsub (str, "\n", "\r\n")
	str = string.gsub (str, "([^%w ])",
		function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = string.gsub (str, " ", "+")
	return str
end

----------------------------------------------------------------------------
-- Insert a (name=value) pair into table [[args]]
-- @param args Table to receive the result.
-- @param name Key for the table.
-- @param value Value for the key.
-- Multi-valued names will be represented as tables with numerical indexes
--	(in the order they came).
----------------------------------------------------------------------------
function insertfield (args, name, value)
	if not args[name] then
		args[name] = value
	else
		local t = type (args[name])
		if t == "string" then
			args[name] = {
				args[name],
				value,
			}
		elseif t == "table" then
			table.insert (args[name], value)
		else
			error ("CGILua fatal error (invalid args table)!")
		end
	end
end

----------------------------------------------------------------------------
-- Parse url-encoded request data 
--   (the query part of the script URL or url-encoded post data)
--
--  Each decoded (name=value) pair is inserted into table [[args]]
----------------------------------------------------------------------------
function parsequery (query, args)
	if type(query) == "string" then
		local insertfield, unescape = insertfield, unescape
		string.gsub (query, "([^&=]+)=([^&=]*)&?",
			function (key, val)
				insertfield (args, unescape(key), unescape(val))
			end)
	end
end

----------------------------------------------------------------------------
-- URL-encode the elements of a table creating a string to be used in a
--   URL for passing data/parameters to another script
----------------------------------------------------------------------------
function encodetable (args)
  if args == nil or next(args) == nil then   -- no args or empty args?
    return ""
  end
  local strp = ""
  for key,val in args do
    strp = strp.."&"..escape(key).."="..escape(val)
  end
  -- remove first & 
  return string.sub(strp,2)
end
