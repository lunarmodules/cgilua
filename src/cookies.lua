----------------------------------------------------------------------------
-- $Id: cookies.lua,v 1.7 2004/04/09 09:19:49 tomas Exp $
--
-- Cookies Library
----------------------------------------------------------------------------

local error = error
local format, gsub, strfind = string.format, string.gsub, string.find
local date = os.date
local cgilua = cgilua

local Public = {}
cookies = Public
setmetatable (Public, {
	__index = function (t,n) error("Error reading undefined variable "..n, 2) end,
})

setfenv (1, Public)

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


function set (name, value, options)
  --cgilua.header("Set-Cookie: "..build(name, value, options).."\n")
  cgilua.header("Set-Cookie", build(name, value, options))
end


function sethtml (name, value, options)
  cgilua.put(format('<meta http-equiv="Set-Cookie" content="%s">', 
                build(name, value, options)))
end


function get (name)
  local cookies = cgilua.servervariable"HTTP_COOKIE" or ""
  cookies = ";" .. cookies .. ";"
  cookies = gsub(cookies, "%s*;%s*", ";")   -- remove extra spaces
  local pattern = ";" .. name .. "=(.-);"
  local _, __, value = strfind(cookies, pattern)
  return value and cgilua.unescape(value)
end


function delete (name, options)
  options = options or {}
  options.expires = 1
  set(name, "xxx", options)
end
