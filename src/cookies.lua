----------------------------------------------------------------------------
-- $Id: cookies.lua,v 1.1 2003/04/07 15:53:52 tomas Exp $
--
-- Cookies Library
----------------------------------------------------------------------------

local Public, Private = {}, {}

cookie = Public

function Private.optional (what, name)
  if name ~= nil and name ~= "" then
    return format("; %s=%s", what, name)
  else
    return ""
  end
end


function Private.build (name, value, options)
  if not name or not value then
    error("cookie needs a name and a value")
  end
  local cookie = name .. "=" .. cgilua.escape(value)
  options = options or {}
  if options.expires then
    local t = date("!%A, %d-%b-%Y %H:%M:%S GMT", options.expires)
    cookie = cookie .. %Private.optional("expires", t)
  end
  cookie = cookie .. %Private.optional("path", options.path)
  cookie = cookie .. %Private.optional("domain", options.domain)
  cookie = cookie .. %Private.optional("secure", options.secure)
  return cookie
end


function Public.set (name, value, options)
  cgilua.httpheader("Set-Cookie: "..%Private.build(name, value, options).."\n")
end


function Public.sethtml (name, value, options)
  cgilua.put(format('<meta http-equiv="Set-Cookie" content="%s">', 
                %Private.build(name, value, options)))
end


function Public.get (name)
  local cookies = getenv("HTTP_COOKIE") or ""
  cookies = ";" .. cookies .. ";"
  cookies = gsub(cookies, "%s*;%s*", ";")   -- remove extra spaces
  local pattern = ";" .. name .. "=(.-);"
  local _, __, value = strfind(cookies, pattern)
  return value and cgilua.unescape(value)
end


function Public.delete (name, options)
  options = options or {}
  options.expires = 1
  %Public.set(name, "xxx", options)
end
