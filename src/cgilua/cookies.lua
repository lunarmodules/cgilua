------------------------------------------------------------------------------
-- Cookies Library
------------------------------------------------------------------------------
-- Based on:
-- https://datatracker.ietf.org/doc/draft-ietf-httpbis-rfc6265bis/
-- https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie
------------------------------------------------------------------------------

local cgilua = require"cgilua"
local os = require"os"
local string = require"string"
local table = require"table"
local urlcode = require"cgilua.urlcode"

local error = error
local format, gsub, strmatch = string.format, string.gsub, string.match
local date = os.date
local escape, unescape = urlcode.escape, urlcode.unescape
local tconcat = table.concat

local header = cgilua.Response.header
local write = cgilua.Response.write
local servervariable = cgilua.servervariable

local M = {}

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
	local cookie = name .. "=" .. escape(value)
	if type(options) == "table" then
		local a = {}

		if tonumber (options.expires) then
			local t = date("!%A, %d-%b-%Y %H:%M:%S GMT", options.expires)
			a[#a+1] = optional("Expires", t)
		else
			a[#a+1] = optional("Expires", options.expires)
		end

		-- Indicates the number of seconds until the cookie expires.
		a[#a+1] = optional("Max-Age", options.max_age)

		-- Domain and Path scope the cookie.
		a[#a+1] = optional("Domain", options.domain)
		a[#a+1] = optional("Path", options.path)

		-- If Partitioned is set, Secure should also be
		-- If SameSite=None, Secure should be set
		if options.secure
			or options.partitioned
			or (options.samesite and options.samesite:lower() == "none") then

			-- Enforces HTTPS transport when required.
			a[#a+1] = "Secure"
		end

		-- Prevent access from client-side JavaScript.
		if options.httponly then
			a[#a+1] = "HttpOnly"
		end

		-- Mark cookie as partitioned (requires Secure).
		if options.partitioned then
			a[#a+1] = "Partitioned"
		end

		-- SameSite controls cross-site cookie sending.
		-- Note: SameSite=None requires Secure (enforced above).
		a[#a+1] = optional("SameSite", options.samesite)

		cookie = cookie..tconcat (a)
	end
	return cookie
end


------------------------------------------------------------------------------
-- Sets a value to a cookie, with the given options.
-- Generates a header "Set-Cookie", thus it can only be used in Lua Scripts.
-- @param name String with the name of the cookie.
-- @param value String with the value of the cookie.
-- @param options Table with the options (optional).
------------------------------------------------------------------------------
function M.set (name, value, options)
	header("Set-Cookie", build(name, value, options))
end


------------------------------------------------------------------------------
-- Sets a value to a cookie, with the given options.
-- Generates an HTML META tag, thus it can be used in Lua Pages.
-- @param name String with the name of the cookie.
-- @param value String with the value of the cookie.
-- @param options Table with the options (optional).
------------------------------------------------------------------------------
function M.sethtml (name, value, options)
	write(format('<meta http-equiv="Set-Cookie" content="%s">',
		build(name, value, options)))
end


------------------------------------------------------------------------------
-- Gets the value of a cookie.
-- @param name String with the name of the cookie.
-- @return String with the value associated with the cookie.
------------------------------------------------------------------------------
function M.get (name)
	local cookies = servervariable"HTTP_COOKIE" or ""
	cookies = ";" .. cookies .. ";"
	cookies = gsub(cookies, "%s*;%s*", ";")	 -- remove extra spaces
	local pattern = ";" .. name .. "=(.-);"
	local value = strmatch(cookies, pattern)
	return value and unescape(value)
end


------------------------------------------------------------------------------
-- Deletes a cookie, by setting its value to "xxx".
-- @param name String with the name of the cookie.
-- @param options Table with the options (optional).
------------------------------------------------------------------------------
function M.delete (name, options)
	M.set(name, "xxx", {
		path = options.path,
		domain = options.domain,
		max_age = "0",
	})
end

return M
