----------------------------------------------------------------------------
-- $Id: cookies.lua,v 1.5 2004/03/25 19:01:39 tomas Exp $
--
-- Cookies Library
----------------------------------------------------------------------------

local Public = {}

cookie = Public

local function optional (what, name)
  if name ~= nil and name ~= "" then
    return format("; %s=%s", what, name)
  else
    return ""
  end
end


local function build (name, value, options)
  if not name or not value then
    error("cookie needs a name and a value")
  end
  local cookie = name .. "=" .. cgilua.escape(value)
  options = options or {}
  if options.expires then
    local t = date("!%A, %d-%b-%Y %H:%M:%S GMT", options.expires)
    cookie = cookie .. optional("expires", t)
  end
  cookie = cookie .. optional("path", options.path)
  cookie = cookie .. optional("domain", options.domain)
  cookie = cookie .. optional("secure", options.secure)
  return cookie
end


function Public.set (name, value, options)
  cgilua.httpheader("Set-Cookie: "..build(name, value, options).."\n")
end


function Public.sethtml (name, value, options)
  cgilua.put(format('<meta http-equiv="Set-Cookie" content="%s">', 
                build(name, value, options)))
end


function Public.get (name)
  local cookies = os.getenv("HTTP_COOKIE") or ""
  cookies = ";" .. cookies .. ";"
  cookies = string.gsub(cookies, "%s*;%s*", ";")   -- remove extra spaces
  local pattern = ";" .. name .. "=(.-);"
  local _, __, value = string.find(cookies, pattern)
  return value and cgilua.unescape(value)
end


function Public.delete (name, options)
  options = options or {}
  options.expires = 1
  Public.set(name, "xxx", options)
end
