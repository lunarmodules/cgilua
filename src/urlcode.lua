----------------------------------------------------------------------------
-- $Id: urlcode.lua,v 1.1 2004/03/25 19:01:39 tomas Exp $
----------------------------------------------------------------------------

local next, tonumber, type = next, tonumber, type
local string = string

----------------------------------------------------------------------------
-- Decode an URL-encoded string (see RFC 2396)
----------------------------------------------------------------------------
function url_unescape (str)
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

----------------------------------------------------------------------------
-- URL-encode a string (see RFC 2396)
----------------------------------------------------------------------------
function url_escape (str)
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
function url_insertfield (args, name, value)
	if not args[name] then
		args[name] = value
	elseif type(args) == "string" then
		args[name] = {
			args[name],
			value,
		}
	else
		table.insert (args, value)
	end
end

----------------------------------------------------------------------------
-- Parse url-encoded request data 
--   (the query part of the script URL or url-encoded post data)
--
--  Each decoded (name=value) pair is inserted into table [[args]]
----------------------------------------------------------------------------
function url_parsequery (query, args)
	if type(query) == "string" then
		local insertfield, unescape = insertfield, url_unescape
		string.gsub (query, "([^&=]+)=([^&=]*)&?",
			function (key, val)
				url_insertfield (args, unescape(key), unescape(val))
			end)
	end
end

----------------------------------------------------------------------------
-- URL-encode the elements of a table creating a string to be used in a
--   URL for passing data/parameters to another script
----------------------------------------------------------------------------
function url_encodetable (args)
  if args == nil or next(args) == nil then   -- no args or empty args?
    return ""
  end
  local strp = ""
  for key,val in args do
    strp = strp.."&"..url_escape(key).."="..url_escape(val)
  end
  -- remove first & 
  return string.sub(strp,2)
end

