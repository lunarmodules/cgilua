----------------------------------------------------------------------------
-- $Id: cgilua.lua,v 1.12 2004/07/07 16:26:17 tomas Exp $
--
-- Auxiliar functions defined for CGILua scripts
----------------------------------------------------------------------------

require"urlcode"
require"prep"
require"post"

local Public = {
	script_path = false,
	escape = url_escape,
	unescape = url_unescape,
	userscriptname = false,
}
cgilua = Public
setmetatable (Public, {
	__index = function (t,n) error("Error reading undefined variable "..n, 2) end,
})

local _require = require
local _loadlib = loadlib

local assert, error, _G, loadstring, loadfile, type, unpack, xpcall = assert, error, _G, loadstring, loadfile, type, unpack, xpcall
local gsub, format, strfind, strlower, strsub = string.gsub, string.format, string.find, string.lower, string.sub
local open = io.open
local getn, tinsert = table.getn, table.insert
local url_encodetable, url_insertfield, url_parsequery = url_encodetable, url_insertfield, url_parsequery
local ap = ap
local post = post
local translate = HTMLPreProcessor.translate
local HTTP_Response, HTTP_Request = HTTP_Response, HTTP_Request

HTMLPreProcessor.setoutfunc "HTTP_Response.write"
HTMLPreProcessor.setcompatmode (true)

-- Internal state variables.
local closefunction, errorhandler, errorlog, erroroutput, libdir, maxfilesize, maxinput, path

setfenv (1, Public)

----------------------------------------------------------------------------
-- Header functions
----------------------------------------------------------------------------
header = HTTP_Response.header

function contentheader (type, subtype)
	HTTP_Response.contenttype (type..'/'..subtype)
end

locationheader = HTTP_Response.redirect

function htmlheader()
	HTTP_Response.contenttype ("text/html")
end

----------------------------------------------------------------------------
-- Create an HTTP header redirecting the browser to another URL
----------------------------------------------------------------------------
function redirect (url, args)
	if strfind(url,"^https?:") then
		local params=""
		if args then
			params = "?"..encodetable(args)
		end
		return locationheader(url..params)
	else
		return locationheader(mkabsoluteurl(mkurlpath(url,args)))
	end
end

----------------------------------------------------------------------------
-- Returns a server variable
----------------------------------------------------------------------------
servervariable = HTTP_Request.servervariable

----------------------------------------------------------------------------
-- Primitive error output function
----------------------------------------------------------------------------
error_log = HTTP_Response.errorlog

----------------------------------------------------------------------------
-- Function 'put' sends its arguments (basically strings of HTML text)
--  to the server
-- Its basic implementation is to use Lua function 'write', which writes
--  each of its arguments (strings or numbers) to file _OUTPUT (a file
--  handle initialized with the file descriptor for stdout)
----------------------------------------------------------------------------
put = HTTP_Response.write

----------------------------------------------------------------------------
-- Remove globals not allowed in CGILua scripts
----------------------------------------------------------------------------
function removeglobals (notallowed)
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
	assert (not strfind (packagename, "%.%."),
		"Package name cannot contain `..'")
	_G.LUA_PATH = format ("%s?/?.lua;%s?.lua;%s?", libdir, libdir, libdir)
	_G.loadlib = _loadlib
	local ret = _require (packagename)
	_G.loadlib = nil
	return ret
end

----------------------------------------------------------------------------
-- Execute a script
--  If an error is found, Lua's error handler is called and this function
--  does not return
----------------------------------------------------------------------------
function doscript (filename)
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
function doif (filename)
	if not filename then return end    -- no file
	local f, err = open(filename)
	if not f then return nil, err end    -- no file (or unreadable file)
	f:close()
	return doscript (filename)
end

---------------------------------------------------------------------------
-- Set the maximum "total" input size allowed (in bytes)
---------------------------------------------------------------------------
function setmaxinput(nbytes)
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
function setmaxfilesize(nbytes)
	maxfilesize = nbytes
end

----------------------------------------------------------------------------
-- Preprocess and include the content of a mixed HTML file into the 
--  currently 'open' HTML document. 
----------------------------------------------------------------------------
function includehtml (filename)
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
function preprocess (filename)
	htmlheader ()
	includehtml (filename)
end

----------------------------------------------------------------------------
-- Parse url-encoded request data 
--   (the query part of the script URL or url-encoded post data)
--
--  Each decoded (name=value) pair is inserted into table [[args]]
----------------------------------------------------------------------------
parsequery = url_parsequery

----------------------------------------------------------------------------
-- URL-encode the elements of a table creating a string to be used in a
--   URL for passing data/parameters to another script
----------------------------------------------------------------------------
encodetable = url_encodetable

----------------------------------------------------------------------------
-- Create an URL path to be used as a link to a CGILua script
----------------------------------------------------------------------------
function mkurlpath (script, args)
	-- URL-encode the parameters to be passed do the script
	local params = ""
	if args then
		params = "?"..encodetable(args)
	end
	if strsub(script,1,1) == "/" then
		return urlpath .. script .. params
	else
		return urlpath .. script_vdir .. script .. params
	end
end

----------------------------------------------------------------------------
-- Create an absolute URL containing the given URL path
----------------------------------------------------------------------------
function mkabsoluteurl (path, protocol)
	if not protocol then protocol = "http" end
	return format("%s://%s:%s%s",
		protocol,
		servervariable"SERVER_NAME",
		servervariable"SERVER_PORT",
		path)
end

----------------------------------------------------------------------------
-- Extract the "directory" and "file" parts of a path
----------------------------------------------------------------------------
function splitpath (path)
	local _,_,dir,file = strfind(path,"^(.-)([^:/\\]*)$")
	return dir,file
end

----------------------------------------------------------------------------
-- Define variables and build `cgi' table.
----------------------------------------------------------------------------
function getparams (args)
	-- Define variables.
	script_pdir, script_file = splitpath (script_path or servervariable"PATH_TRANSLATED")
	script_vpath = servervariable"PATH_INFO"
	script_vdir = splitpath (servervariable"PATH_INFO")
	urlpath = servervariable"SCRIPT_NAME"
	-- Fill in args table.
	if servervariable"REQUEST_METHOD" == "POST" then
		post.parsedata {
			read = HTTP_Request.getpostdata,
			discardinput = ap and ap.discard_request_body,
			content_type = servervariable"CONTENT_TYPE",
			content_length = servervariable"CONTENT_LENGTH",
			maxinput = maxinput,
			maxfilesize = maxfilesize,
			args = args,
		}
	end
	parsequery (servervariable"QUERY_STRING", args)
end

----------------------------------------------------------------------------
-- Stores all script handlers and the file extensions used to identify
-- them.
local script_handlers = {
}

----------------------------------------------------------------------------
-- Default handler.
-- Sends the contents of the file to the output without processing it.
----------------------------------------------------------------------------
local function default_handler (filename)
	htmlheader ()
	local fh = assert (open (filename))
	local prog = fh:read("*a")
	fh:close()
	put (prog)
end

----------------------------------------------------------------------------
-- Add a script handler.
-- @param file_extension String with the lower-case extension of the script.
-- @param func Function to handle this kind of scripts.
----------------------------------------------------------------------------
function addscripthandler (file_extension, func)
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
function getscripthandler (path)
	local i,f, ext = strfind (path, "%.([^.]+)$")
	return script_handlers[strlower(ext or '')] or default_handler
end

---------------------------------------------------------------------------
-- Execute the given path with the corresponding handler.
-- @param path String with a script path.
-- @return The returned values from the script.
---------------------------------------------------------------------------
function handle (path)
	return getscripthandler (path) (path)
end

---------------------------------------------------------------------------
-- Set CGILua's default libraries directory
---------------------------------------------------------------------------
function setlibdir(newlibdir)
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
function seterrorhandler (f)
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
function seterroroutput (f)
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
function seterrorlog (f)
	local tf = type(f)
	if tf == "function" then
		errorlog = f
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Executes a function with an error handler.
---------------------------------------------------------------------------
function pcall (f, ...)
	local result = { xpcall (function () return f(unpack(arg)) end,
		errorhandler) }
	if not result[1] then
		erroroutput (errmsg)
		errorlog (errmsg)
	end
	return unpack (result)
end

----------------------------------------------------------------------------
-- Stores all close functions in order they are set.
local close_functions = {
}

---------------------------------------------------------------------------
-- Set "close" function
--
-- This function will be called after the user script execution
---------------------------------------------------------------------------
function addclosefunction (f)
	local tf = type(f)
	if tf == "function" then
		tinsert (close_functions, f)
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Close function.
---------------------------------------------------------------------------
function close()
	for i = getn(close_functions), 1, -1 do
		close_functions[i]()
	end
end

----------------------------------------------------------------------------
-- Stores all open functions in order they are set.
local open_functions = {
}

---------------------------------------------------------------------------
-- Set "open" function
--
-- This function will be called before the user script (and environment)
-- execution
---------------------------------------------------------------------------
function addopenfunction (f)
	local tf = type(f)
	if tf == "function" then
		tinsert (open_functions, f)
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Open function.
---------------------------------------------------------------------------
function _open()
	for i = getn(open_functions), 1, -1 do
		open_functions[i]()
	end
end

---------------------------------------------------------------------------
-- Resets CGILua's state.
---------------------------------------------------------------------------
function reset ()
	closefunction = nil
	libdir = nil
	maxfilesize = nil
	maxinput = nil
	path = nil
	-- Error treatment
	errorhandler = nil
	errorlog = nil
	erroroutput = nil
	-- Handlers
	script_handlers = {}
	open_function = {}
	close_functions = {}
end
