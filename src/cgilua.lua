----------------------------------------------------------------------------
-- $Id: cgilua.lua,v 1.3 2004/03/25 19:01:39 tomas Exp $
--
-- Auxiliar functions defined for CGILua scripts
----------------------------------------------------------------------------

require"urlcode"
require"prep"
require"post"

local Public = {}
cgilua = Public

local _loadlib = loadlib
local _require = require

local assert, error, _G, loadstring, loadfile, _TRACEBACK, type, unpack, xpcall = assert, error, _G, loadstring, loadfile, _TRACEBACK, type, unpack, xpcall
local gsub, format, strfind, strlower, strsub = string.gsub, string.format, string.find, string.lower, string.sub
local open = io.open
local getn = table.getn
local url_encodetable, url_escape, url_insertfield, url_parsequery, url_unescape = url_encodetable, url_escape, url_insertfield, url_parsequery, url_unescape
local ap = ap
local post = post
local translate = HTMLPreProcessor.translate
local HTTP_Response, HTTP_Request = HTTP_Response, HTTP_Request

HTMLPreProcessor.setoutfunc "HTTP_Response.write"
HTMLPreProcessor.setcompatmode (true)

-- Internal state variables.
local closefunction, errorhandler, errorlog, erroroutput, libdir, maxfilesize, maxinput, path

setfenv (1, {
	__fenv = 1,
	__index = function (t,n) error("Accessing undefined variable "..n, 2) end,
})

----------------------------------------------------------------------------
-- Header functions
----------------------------------------------------------------------------
function Public.contentheader (type, subtype)
	HTTP_Response.contenttype (type..'/'..subtype)
end

Public.locationheader = HTTP_Response.redirect

function Public.htmlheader()
	HTTP_Response.contenttype ("text/html")
end

----------------------------------------------------------------------------
-- Create an HTTP header redirecting the browser to another URL
----------------------------------------------------------------------------
function Public.redirect (url, args)
	if strfind(url,"http:") then
		local params=""
		if args then
			params = "?"..Public.encodetable(args)
		end
		Public.locationheader(url..params)
	else
		Public.locationheader(Public.mkabsoluteurl(Public.mkurlpath(url,args)))
	end
end

----------------------------------------------------------------------------
-- Returns a server variable
----------------------------------------------------------------------------
Public.servervariable = HTTP_Request.servervariable

----------------------------------------------------------------------------
-- Function 'put' sends its arguments (basically strings of HTML text)
--  to the server
-- Its basic implementation is to use Lua function 'write', which writes
--  each of its arguments (strings or numbers) to file _OUTPUT (a file
--  handle initialized with the file descriptor for stdout)
----------------------------------------------------------------------------
Public.put = HTTP_Response.write

----------------------------------------------------------------------------
-- Remove globals not allowed in CGILua scripts
----------------------------------------------------------------------------
function Public.removeglobals (notallowed)
	for i=1,getn(notallowed) do
		local g = notallowed[i]
		if type(_G[g]) ~= "function" then
			_G[g] = nil
		else
			_G[g] = function()
				 error("Function '"..g.."' is not allowed in CGILua scripts.")
			end
		end
	end
end

----------------------------------------------------------------------------
-- Redefine require.
----------------------------------------------------------------------------
_G.require = function (packagename)
	-- packagename cannot contain some special punctuation characters
	assert (not (strfind (packagename, "[^%w_.-]") or
			strfind (packagename, "%.%.")),
		"Package name cannot contain punctuation characters")
	_G.LUA_PATH = format ("%s?;%s?.lua", libdir, libdir)
	return _require (packagename)
end

----------------------------------------------------------------------------
-- Execute a script
--  If an error is found, Lua's error handler is called and this function
--  does not return
----------------------------------------------------------------------------
function Public.doscript (filename)
	local res, err = loadfile(filename)
	if not res then
		error (format ("Cannot execute `%s'. Exiting.\n%s", filename, err))
	else
		return res ()
	end
end

----------------------------------------------------------------------------
-- Execute the file if there is no "file error".
--  If an error is found, and it is not a "file error", Lua 'error'
--  is called and this function does not return
----------------------------------------------------------------------------
function Public.doif (filename)
	if not filename then return end    -- no file
	local f, err = open(filename)
	if not f then return nil, err end    -- no file (or unreadable file)
	f:close()
	return Public.doscript (filename)
end

---------------------------------------------------------------------------
-- Set the maximum "total" input size allowed (in bytes)
---------------------------------------------------------------------------
function Public.setmaxinput(nbytes)
	-- can only be set once (by CGILua's mainscript)
	if maxinput then
		error("Maximum input size redefinition is not allowed")
	end
	maxinput = nbytes
end

---------------------------------------------------------------------------
-- Set the maximum size for an "uploaded" file (in bytes)
--   (can be redefined by a script but "maxinputsize" is checked first)
---------------------------------------------------------------------------
function Public.setmaxfilesize(nbytes)
	maxfilesize = nbytes
end

----------------------------------------------------------------------------
-- Preprocess and include the content of a mixed HTML file into the 
--  currently 'open' HTML document. 
----------------------------------------------------------------------------
function Public.includehtml (filename)
	local fh = assert (open (filename))
	local prog = fh:read("*a")
	fh:close()
	prog = translate (prog, "file "..filename)
	if prog then
		local f, err = loadstring (prog, "@"..filename)
		if f then
			f()
		else
			error (err)
		end
	end
end

----------------------------------------------------------------------------
-- Preprocess the content of a mixed HTML file and output a complete
--   HTML document ( a 'Content-type' header is inserted before the
--   preprocessed HTML )
----------------------------------------------------------------------------
function Public.preprocess (filename)
	Public.htmlheader ()
	Public.includehtml (filename)
end

----------------------------------------------------------------------------
-- Parse url-encoded request data 
--   (the query part of the script URL or url-encoded post data)
--
--  Each decoded (name=value) pair is inserted into table [[args]]
----------------------------------------------------------------------------
Public.parsequery = url_parsequery

----------------------------------------------------------------------------
-- URL-encode the elements of a table creating a string to be used in a
--   URL for passing data/parameters to another script
----------------------------------------------------------------------------
Public.encodetable = url_encodetable

----------------------------------------------------------------------------
-- Create an URL path to be used as a link to a CGILua script
----------------------------------------------------------------------------
function Public.mkurlpath (script, args)
	-- URL-encode the parameters to be passed do the script
	local params = ""
	if args then
		params = "?"..Public.encodetable(args)
	end
	if strsub(script,1,1) == "/" then
		return Public.urlpath .. script .. params
	else
		return Public.urlpath .. Public.script_vdir .. script .. params
	end
end

----------------------------------------------------------------------------
-- Create an absolute URL containing the given URL path
----------------------------------------------------------------------------
function Public.mkabsoluteurl (path, protocol)
	if not protocol then protocol = "http" end
	return format("%s://%s:%s%s",
		protocol,
		HTTP_Request.servervariable"SERVER_NAME",
		HTTP_Request.servervariable"SERVER_PORT",
		path)
end

----------------------------------------------------------------------------
-- Extract the "directory" and "file" parts of a path
----------------------------------------------------------------------------
function Public.splitpath (path)
	local _,_,dir,file = strfind(path,"^(.-)([^:/\\]*)$")
	return dir,file
end

----------------------------------------------------------------------------
-- Define variables and build `cgi' table.
----------------------------------------------------------------------------
function Public.getparams (args)
	local P = Public
	-- Define variables.
	P.script_pdir, P.script_file = P.splitpath (P.script_path)
	P.script_vpath = HTTP_Request.servervariable"PATH_INFO"
	P.script_vdir = P.splitpath (HTTP_Request.servervariable"PATH_INFO")
	P.urlpath = HTTP_Request.servervariable"SCRIPT_NAME"
	-- Fill in args table.
	if HTTP_Request.servervariable"REQUEST_METHOD" == "POST" then
		post.parsedata {
			read = HTTP_Request.getpostdata,
			discardinput = ap and ap.discard_request_body,
			content_type = HTTP_Request.servervariable"CONTENT_TYPE",
			content_length = HTTP_Request.servervariable"CONTENT_LENGTH",
			maxinput = maxinput,
			maxfilesize = maxfilesize,
			args = args,
		}
	end
	Public.parsequery (HTTP_Request.servervariable"QUERY_STRING", args)
end

----------------------------------------------------------------------------
-- Stores all script handlers and the file extensions used to identify
-- them.
local script_handlers = {
}

----------------------------------------------------------------------------
-- Add a script handler.
-- @param file_extension String with the lower-case extension of the script.
-- @param func Function to handle this kind of scripts.
----------------------------------------------------------------------------
function Public.addscripthandler (file_extension, func)
	assert (type(file_extension) == "string", "File extension must be a string")
	if strfind (file_extension, '%.', 1) then
		file_extension = strsub (file_extension, 2)
	end
	file_extension = strlower(file_extension)
	assert (type(func) == "function", "Handler must be a function")

	script_handlers[file_extension] = func
end

----------------------------------------------------------------------------
-- Obtains the handler corresponding to the given script path.
-- @param path String with a script path.
-- @return Function that handles it or nil.
----------------------------------------------------------------------------
function Public.getscripthandler (path)
	local i,f, ext = strfind (path, "%.([^.]+)$")
	return script_handlers[strlower(ext or '')]
end

---------------------------------------------------------------------------
-- Execute the given path with the corresponding handler.
-- @param path String with a script path.
-- @return The returned values from the script.
---------------------------------------------------------------------------
function Public.handle (path)
	return Public.getscripthandler (path) (path)
end

---------------------------------------------------------------------------
-- Set CGILua's default libraries directory
---------------------------------------------------------------------------
function Public.setlibdir(newlibdir)
	-- can only be set once (by CGILua's mainscript)
	if libdir then
		error("Libraries directory redefinition is not allowed")
	end
	newlibdir = gsub (newlibdir, "([^/])$", "%1/")
	libdir = newlibdir
end

---------------------------------------------------------------------------
-- Sets "errorhandler" function
-- This function is called by Lua when an error occurs.
-- It receives the error message generated by Lua and it is resposible
-- for the final message which should be returned.
---------------------------------------------------------------------------
function Public.seterrorhandler (f)
	local tf = type(f)
	if tf == "function" then
		errorhandler = f
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Sets "erroroutput" function
-- This function is called to generate the error output.
---------------------------------------------------------------------------
function Public.seterroroutput (f)
	local tf = type(f)
	if tf == "function" then
		erroroutput = f
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Sets "errorlog" function
-- This function will be called to log the error message.
---------------------------------------------------------------------------
function Public.seterrorlog (f)
	local tf = type(f)
	if tf == "function" then
		errorlog = f
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Execute a function with an error handler.
---------------------------------------------------------------------------
function Public.pcall (f, ...)
	local ok, errmsg = xpcall (function () return f(unpack(arg)) end,
		errorhandler)
	if not ok then
		errorlog (errmsg)
		erroroutput (errmsg)
	end
end

---------------------------------------------------------------------------
-- Set "close" function
--
-- This function will be called after the user script execution
---------------------------------------------------------------------------
function Public.setclosefunction (f)
	local tf = type(f)
	if tf == "function" then
		closefunction = f
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Close function.
---------------------------------------------------------------------------
function Public.close()
	if closefunction then
		closefunction()
	end
end

---------------------------------------------------------------------------
-- Resets CGILua's state.
---------------------------------------------------------------------------
function Public.reset ()
	closefunction = nil
	libdir = nil
	maxfilesize = nil
	maxinput = nil
	path = nil
	-- Error treatment
	errorhandler = nil
	errorlog = nil
	erroroutput = nil
	-- Handlers ???
end

Public.seterrorhandler (_TRACEBACK)
Public.seterroroutput (function (msg)
	Public.contentheader("text", "plain")
	Public.put ("There was an error.\nProper information was written to the error log.")
end)
Public.seterrorlog (function (msg)
	HTTP_Response.errorlog (msg)
end)
