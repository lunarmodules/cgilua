----------------------------------------------------------------------------
-- $Id: cgilua.lua,v 1.16 2005/02/01 15:04:15 carregal Exp $
--
-- Auxiliar functions defined for CGILua scripts
----------------------------------------------------------------------------

require"cgilua.urlcode"
require"cgilua.prep"
require"cgilua.post"
require"lfs"

local _require = require
local _loadlib = loadlib

local assert, error, _G, loadstring, loadfile, _pcall, type, unpack, xpcall = assert, error, _G, loadstring, loadfile, pcall, type, unpack, xpcall
local gsub, format, strfind, strlower, strsub = string.gsub, string.format, string.find, string.lower, string.sub
local _open = io.open
local getn, tinsert, tremove = table.getn, table.insert, table.remove
local ap = ap
local SAPI = SAPI
local lfs = lfs
local urlcode = cgilua.urlcode
local post = cgilua.post
local prep = cgilua.prep
local translate = prep.translate

prep.setoutfunc ("SAPI.Response.write")
prep.setcompatmode (true)

-- Internal state variables.
local default_errorhandler = debug.traceback
local errorhandler = default_errorhandler
local default_erroroutput = function (msg)
	-- Logging error
	SAPI.Response.errorlog (msg)
	SAPI.Response.errorlog (SAPI.Request.servervariable"REMOTE_ADDR")
	SAPI.Response.errorlog (os.date())
	-- Building user message
	SAPI.Response.contenttype ("text/html")
	msg = string.gsub (string.gsub (msg, "\n", "<br>\n"), "\t", "&nbsp;&nbsp;")
	SAPI.Response.write (msg)
end
local erroroutput = default_erroroutput
local default_maxfilesize = 512 * 1024
local maxfilesize = default_maxfilesize
local default_maxinput = 1024 * 1024
local maxinput = default_maxinput
local lua_path = package.path
local lua_cpath = package.cpath

module (arg and arg[1])

_COPYRIGHT = "Copyright (C) 2003-2005 Kepler Project"
_DESCRIPTION = "CGILua is a tool for creating dynamic HTML pages and manipulating input data from forms"
_NAME = "CGILua"
_VERSION = "5.0b3"
script_path = false

----------------------------------------------------------------------------
-- Header functions
----------------------------------------------------------------------------
header = SAPI.Response.header

function contentheader (type, subtype)
	SAPI.Response.contenttype (type..'/'..subtype)
end

locationheader = SAPI.Response.redirect

function htmlheader()
	SAPI.Response.contenttype ("text/html")
end

----------------------------------------------------------------------------
-- Create an HTTP header redirecting the browser to another URL
----------------------------------------------------------------------------
function redirect (url, args)
	if strfind(url,"^https?:") then
		local params=""
		if args then
			params = "?"..urlcode.encodetable(args)
		end
		return locationheader(url..params)
	else
		return locationheader(mkabsoluteurl(mkurlpath(url,args)))
	end
end

----------------------------------------------------------------------------
-- Returns a server variable
----------------------------------------------------------------------------
servervariable = SAPI.Request.servervariable

----------------------------------------------------------------------------
-- Primitive error output function
----------------------------------------------------------------------------
errorlog = SAPI.Response.errorlog

----------------------------------------------------------------------------
-- Function 'put' sends its arguments (basically strings of HTML text)
--  to the server
-- Its basic implementation is to use Lua function 'write', which writes
--  each of its arguments (strings or numbers) to file _OUTPUT (a file
--  handle initialized with the file descriptor for stdout)
----------------------------------------------------------------------------
put = SAPI.Response.write

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
-- Pack results of a function call
----------------------------------------------------------------------------
function pack (...) return arg end

----------------------------------------------------------------------------
-- Redefine require.
----------------------------------------------------------------------------
_G.require = function (packagename)
	-- packagename cannot contain some special punctuation characters
	assert (not strfind (packagename, "%.%."),
		"Package name cannot contain `..'")
	_G.loadlib = _loadlib
	_G.package.path = lua_path
	_G.package.cpath = lua_cpath
	local ret = pack (_require (packagename))
	_G.loadlib = nil
	return unpack (ret)
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
	local f, err = _open(filename)
	if not f then return nil, err end    -- no file (or unreadable file)
	f:close()
	return doscript (filename)
end

---------------------------------------------------------------------------
-- Set the maximum "total" input size allowed (in bytes)
---------------------------------------------------------------------------
function setmaxinput(nbytes)
	maxinput = nbytes
end

---------------------------------------------------------------------------
-- Set the maximum size for an "uploaded" file (in bytes)
-- Might be less or equal than maxinput.
---------------------------------------------------------------------------
function setmaxfilesize(nbytes)
	maxfilesize = nbytes
end

----------------------------------------------------------------------------
-- Preprocess and include the content of a mixed HTML file into the 
--  currently 'open' HTML document. 
----------------------------------------------------------------------------
function includehtml (filename)
	local fh = assert (_open (filename))
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
-- Builds a handler that sends a header and the contents of the given file.
-- Sends the contents of the file to the output without processing it.
----------------------------------------------------------------------------
function buildplainhandler (type, subtype)
	return function (filename)
		contentheader (type, subtype)
		local fh = assert (_open (filename))
		local prog = fh:read("*a")
		fh:close()
		put (prog)
	end
end

----------------------------------------------------------------------------
-- Builds a handler that sends a header and the processed file.
-- Sends the contents of the file to the output without processing it.
----------------------------------------------------------------------------
function buildprocesshandler (type, subtype)
	return function (filename)
		contentheader (type, subtype)
		includehtml (filename)
	end
end

----------------------------------------------------------------------------
-- Create an URL path to be used as a link to a CGILua script
----------------------------------------------------------------------------
function mkurlpath (script, args)
	-- URL-encode the parameters to be passed do the script
	local params = ""
	if args then
		params = "?"..urlcode.encodetable(args)
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
local function getparams (args)
	-- Define variables.
	script_pdir, script_file = splitpath (script_path or servervariable"PATH_TRANSLATED")
	local vpath = servervariable"PATH_INFO"
	script_vpath = vpath
	if vpath and vpath ~= "" then
		script_vdir = splitpath (vpath)
		urlpath = servervariable"SCRIPT_NAME"
	else
		script_vdir = splitpath (servervariable"SCRIPT_NAME")
		urlpath = ""
	end
	-- Fill in args table.
	if servervariable"REQUEST_METHOD" == "POST" then
		post.parsedata {
			read = SAPI.Request.getpostdata,
			discardinput = ap and ap.discard_request_body,
			content_type = servervariable"CONTENT_TYPE",
			content_length = servervariable"CONTENT_LENGTH",
			maxinput = maxinput,
			maxfilesize = maxfilesize,
			args = args,
		}
	end
	urlcode.parsequery (servervariable"QUERY_STRING", args)
end

----------------------------------------------------------------------------
-- Stores all script handlers and the file extensions used to identify
-- them.
local script_handlers = {}

----------------------------------------------------------------------------
-- Default handler.
-- Sends the contents of the file to the output without processing it.
----------------------------------------------------------------------------
local function default_handler (filename)
	htmlheader ()
	local fh = assert (_open (filename))
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

---------------------------------------------------------------------------
-- Obtains the handler corresponding to the given script path.
-- @param path String with a script path.
-- @return Function that handles it or nil.
----------------------------------------------------------------------------
function getscripthandler (path)
	local i,f, ext = strfind (path, "%.([^.]+)$")
	return script_handlers[strlower(ext or '')]
end

---------------------------------------------------------------------------
-- Execute the given path with the corresponding handler.
-- @param path String with a script path.
-- @return The returned values from the script.
---------------------------------------------------------------------------
function handle (path)
	local h = assert (getscripthandler (path), "There is no handler defined to process this kind of file ("..path..")")
	return h (path)
end

---------------------------------------------------------------------------
-- Set _PATH used by scripts by providing the user libraries directory.
-- @param newlibdir String with a full path.
---------------------------------------------------------------------------
function setlibdir(newlibdir)
	newlibdir = gsub (newlibdir, "([^/])$", "%1/")
	newlibdir = format ("%s?/?.lua;%s?.lua;%s?", newlibdir, newlibdir,
		newlibdir)
	lua_path = newlibdir
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
-- Executes a function with an error handler.
---------------------------------------------------------------------------
function pcall (f, ...)
	local result = pack (xpcall (function () return f(unpack(arg)) end,
		errorhandler))
	if not result[1] then
		erroroutput (result[2])
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
local function close()
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
local function open()
	for i = getn(open_functions), 1, -1 do
		open_functions[i]()
	end
end

---------------------------------------------------------------------------
-- Resets CGILua's state.
---------------------------------------------------------------------------
local function reset ()
	--lua_path = nil
	maxfilesize = default_maxfilesize
	maxinput = default_maxinput
	-- Error Handling
	errorhandler = default_errorhandler
	erroroutput = default_erroroutput
	-- Handlers
	script_handlers = {}
	open_function = {}
	close_functions = {}
end

---------------------------------------------------------------------------
-- Request processing.
---------------------------------------------------------------------------
function main ()
	-- Default values
	addscripthandler ("lua", doscript)
	addscripthandler ("lp", preprocess)
	-- Configuring CGILua (trying to load cgilua/conf.lua)
	pcall (_G.require, "cgilua.config")
	-- Cleaning environment
	removeglobals {
		"os.execute",
		"loadlib",
		"cgilua.setlibdir",
	}
	-- Defining directory variables and building `cgi' table
	_G.cgi = {}
	pcall (getparams, _G.cgi)
	-- Changing curent directory to the script's "physical" dir
	local curr_dir = lfs.currentdir ()
	pcall (lfs.chdir, script_pdir)
	-- Opening function
	pcall (open)
	-- Executing script
	local result = pack (pcall (handle, script_file))
	-- Closing function
	pcall (close)
	-- Cleanup
	reset ()
	-- Changing to original directory
	pcall (lfs.chdir, curr_dir)
	-- Returning results to server
	tremove (result, 1)
	return unpack (result)
end
