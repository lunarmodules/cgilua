----------------------------------------------------------------------------
-- CGILua library.
--
-- @release $Id: cgilua.lua,v 1.85 2009/06/28 22:42:34 tomas Exp $
----------------------------------------------------------------------------

local _G, SAPI = _G, SAPI
local urlcode = require"cgilua.urlcode"
local lp = require"cgilua.lp"
local lfs = require"lfs"
local debug = require"debug"
local assert, error, ipairs, select, tostring, type, unpack, xpcall = assert, error, ipairs, select, tostring, type, unpack, xpcall
local pairs = pairs
local gsub, format, strfind, strlower, strsub, match = string.gsub, string.format, string.find, string.lower, string.sub, string.match
local setmetatable = setmetatable
local _open = io.open
local tinsert, tremove, concat = table.insert, table.remove, table.concat
local date = os.date
local os_tmpname = os.tmpname
local getenv = os.getenv
local remove = os.remove
local seeall = package.seeall

lp.setoutfunc ("cgilua.put")
lp.setcompatmode (true)

--module ("cgilua")

local _M = {
	_COPYRIGHT = "Copyright (C) 2003-2013 Kepler Project",
	_DESCRIPTION = "CGILua is a tool for creating dynamic Web pages and manipulating input data from forms",
	_VERSION = "CGILua 5.2",
}

--
-- Internal state variables.
local _default_errorhandler = debug.traceback
local _errorhandler = _default_errorhandler
local _default_erroroutput = function (msg)
	if type(msg) ~= "string" and type(msg) ~= "number" then
		msg = format ("bad argument #1 to 'error' (string expected, got %s)", type(msg))
	end
  
	-- Logging error
	SAPI.Response.errorlog (msg)
	SAPI.Response.errorlog (" ")

	SAPI.Response.errorlog (SAPI.Request.servervariable"REMOTE_ADDR")
	SAPI.Response.errorlog (" ")

	SAPI.Response.errorlog (date())
	SAPI.Response.errorlog ("\n")

	-- Building user message
	msg = gsub (gsub (msg, "\n", "<br>\n"), "\t", "&nbsp;&nbsp;")
	SAPI.Response.contenttype ("text/html")
	SAPI.Response.write ("<html><head><title>CGILua Error</title></head><body>" .. msg .. "</body></html>")
end
local _erroroutput = _default_erroroutput
local _default_maxfilesize = 512 * 1024
local _maxfilesize = _default_maxfilesize
local _default_maxinput = 1024 * 1024
local _maxinput = _default_maxinput
_M.script_path = false

--
-- Header functions

----------------------------------------------------------------------------
-- Sends a header.
-- @name header
-- @class function
-- @param header String with the header.
-- @param value String with the corresponding value.
----------------------------------------------------------------------------
_M.header = SAPI.Response.header

----------------------------------------------------------------------------
-- Sends a Content-type header.
-- @param type String with the type of the header.
-- @param subtype String with the subtype of the header.
----------------------------------------------------------------------------
function _M.contentheader (type, subtype)
	SAPI.Response.contenttype (type..'/'..subtype)
end

----------------------------------------------------------------------------
-- Sends the HTTP header "text/html".
----------------------------------------------------------------------------
function _M.htmlheader()
	SAPI.Response.contenttype ("text/html")
end

----------------------------------------------------------------------------
-- Sends an HTTP header redirecting the browser to another URL
-- @param url String with the URL.
-- @param args Table with the arguments (optional).
----------------------------------------------------------------------------
function _M.redirect (url, args)
	if strfind(url,"^https?:") then
		local params=""
		if args then
			params = "?"..urlcode.encodetable(args)
		end
		return SAPI.Response.redirect(url..params)
	else
		return SAPI.Response.redirect(mkabsoluteurl(mkurlpath(url,args)))
	end
end

----------------------------------------------------------------------------
-- Returns a server variable
-- @name servervariable
-- @class function
-- @param name String with the name of the server variable.
-- @return String with the value of the server variable.
----------------------------------------------------------------------------
_M.servervariable = SAPI.Request.servervariable

----------------------------------------------------------------------------
-- Primitive error output function
-- @param msg String (or number) with the message.
-- @param level String with the error level (optional).
----------------------------------------------------------------------------
function _M.errorlog (msg, level)
	local t = type(msg)
	if t == "string" or t == "number" then
		SAPI.Response.errorlog (msg, level)
	else
		error ("bad argument #1 to `cgilua.errorlog' (string expected, got "..t..")", 2)
	end
end

----------------------------------------------------------------------------
-- Converts all its arguments to strings before sending them to the server.
----------------------------------------------------------------------------
function _M.print (...)
	local args = { ... }
	for i = 1, select("#",...) do
		args[i] = tostring(args[i])
	end
	SAPI.Response.write (concat(args,"\t"))
	SAPI.Response.write ("\n")
end

----------------------------------------------------------------------------
-- Function 'put' sends its arguments (basically strings of HTML text)
--  to the server
-- Its basic implementation is to use Lua function 'write', which writes
--  each of its arguments (strings or numbers) to file _OUTPUT (a file
--  handle initialized with the file descriptor for stdout)
-- @name put
-- @class function
-- @param s String (or number) with output.
----------------------------------------------------------------------------
_M.put = SAPI.Response.write

-- Returns the current errorhandler
function _M._geterrorhandler(msg)
	return _errorhandler(msg)
end

----------------------------------------------------------------------------
-- Executes a function using the CGILua error handler.
-- @param f Function to be called.
----------------------------------------------------------------------------
function _M.pcall (f)
	local results = {xpcall (f, _errorhandler)}
	local ok = results[1]
	tremove(results, 1)
	if ok then
		if #results == 0 then results = { true } end
		return unpack(results)
	else
		_erroroutput (unpack(results))
	end
end

local function buildscriptenv()
	local env = { print = _M.print, write = _M.put }
	setmetatable(env, { __index = _G, __newindex = _G })
	return env
end

----------------------------------------------------------------------------
-- Execute a script
--  If an error is found, Lua's error handler is called and this function
--  does not return
-- @param filename String with the name of the file to be processed.
-- @return The result of the execution of the file.
----------------------------------------------------------------------------
function _M.doscript (filename)
	local env = buildscriptenv()
	local f, err = loadfile(filename, "bt", env)
	if not f then
		error (format ("Cannot execute `%s'. Exiting.\n%s", filename, err))
	else
		return _M.pcall(f)
	end
end

----------------------------------------------------------------------------
-- Execute the file if there is no "file error".
--  If an error is found, and it is not a "file error", Lua 'error'
--  is called and this function does not return
-- @param filename String with the name of the file to be processed.
-- @return The result of the execution of the file or nil (in case the
--      file does not exists or if it cannot be opened).
-- @return It could return an error message if the file cannot be opened.
----------------------------------------------------------------------------
function _M.doif (filename)
        if not filename then return end    -- no file
        local f, err = _open(filename)
        if not f then return nil, err end    -- no file (or unreadable file)
        f:close()
        return doscript (filename)
end

---------------------------------------------------------------------------
-- Set the maximum "total" input size allowed (in bytes)
-- @param nbytes Number of the maximum size (in bytes) of the whole POST data.
---------------------------------------------------------------------------
function _M.setmaxinput(nbytes)
        _maxinput = nbytes
end

---------------------------------------------------------------------------
-- Set the maximum size for an "uploaded" file (in bytes)
-- Might be less or equal than _maxinput.
-- @param nbytes Number of the maximum size (in bytes) of a file.
---------------------------------------------------------------------------
function _M.setmaxfilesize(nbytes)
        _maxfilesize = nbytes
end


-- Default path for temporary files
_M.tmp_path = _G.CGILUA_TMP or getenv("TEMP") or getenv ("TMP") or "/tmp"

-- Default function for temporary names
-- @returns a temporay name using os.tmpname
function _M.tmpname ()
    local tempname = os_tmpname()
    -- Lua os.tmpname returns a full path in Unix, but not in Windows
    -- so we strip the eventual prefix
    tempname = gsub(tempname, "(/tmp/)", "")
    return tempname
end

local _tmpfiles = {}

---------------------------------------------------------------------------
-- Returns a temporary file in a directory using a name generator
-- @param dir Base directory for the temporary file
-- @param namefunction Name generator function
---------------------------------------------------------------------------
function _M.tmpfile(dir, namefunction)
	dir = dir or tmp_path
	namefunction = namefunction or _M.tmpname
	local tempname = namefunction()
	local filename = dir.."/"..tempname
	local file, err = _open(filename, "wb+")
	if file then
		tinsert(_tmpfiles, {name = filename, file = file})
	end
	return file, err
end


----------------------------------------------------------------------------
-- Preprocess the content of a mixed HTML file and output a complete
--   HTML document ( a 'Content-type' header is inserted before the
--   preprocessed HTML )
-- @param filename String with the name of the file to be processed.
-- @param env Optional environment
----------------------------------------------------------------------------
function _M.handlelp (filename, env)
	env = env or _M.buildscriptenv()
	_M.htmlheader ()
	lp.include (filename, env)
end

----------------------------------------------------------------------------
-- Builds a handler that sends a header and the contents of the given file.
-- Sends the contents of the file to the output without processing it.
-- @param type String with the type of the header.
-- @param subtype String with the subtype of the header.
-- @return Function (which receives a filename as argument) that produces
--      the header and copies the content of the given file.
----------------------------------------------------------------------------
function _M.buildplainhandler (type, subtype)
	return function (filename)
		local fh, err = _open (filename, "rb")
		local contents = ""
		if fh then
			contents = fh:read("*a")
			fh:close()
		else
			error(err)
		end
		_M.header("Content-Lenght", #contents)
		_M.contentheader (type, subtype)
		_M.put (contents)
	end
end

----------------------------------------------------------------------------
-- Builds a handler that sends a header and the processed file.
-- Processes the file as a Lua Page.
-- @param type String with the type of the header.
-- @param subtype String with the subtype of the header.
-- @return Function (which receives a filename as argument) that produces
--      the header and processes the given file.
----------------------------------------------------------------------------
function _M.buildprocesshandler (type, subtype)
	return function (filename)
		local env = buildscriptenv()
		_M.contentheader (type, subtype)
		lp.include (filename, env)
	end
end

----------------------------------------------------------------------------
-- Builds the default handler table from cgilua.mime
----------------------------------------------------------------------------
local function buildhandlers()
	local mime = _G.require "cgilua.mime"
	for ext, mediatype in pairs(mime) do
		local t, st = match(mediatype, "([^/]*)/([^/]*)")
		_M.addscripthandler(ext, _M.buildplainhandler(t, st))
	end
end

----------------------------------------------------------------------------
-- Create an URL path to be used as a link to a CGILua script
-- @param script String with the name of the script.
-- @param args Table with arguments to script (optional).
-- @return String in URL format.
----------------------------------------------------------------------------
function _M.mkurlpath (script, args)
	-- URL-encode the parameters to be passed do the script
	local params = ""
	if args then
		params = "?"..urlcode.encodetable(args)
	end
	if strsub(script,1,1) == "/" then
		return script .. params
	else
		return script_vdir .. script .. params
	end
end

----------------------------------------------------------------------------
-- Create an absolute URL containing the given URL path
-- @param path String with the path.
-- @param protocol String with the name of the protocol (default = "http").
-- @return String in URL format.
----------------------------------------------------------------------------
function _M.mkabsoluteurl (path, protocol)
	protocol = protocol or "http"
	if path:sub(1,1) ~= '/' then
		path = '/'..path
	end
	return format("%s://%s:%s%s",
		protocol,
		_M.servervariable"SERVER_NAME",
		_M.servervariable"SERVER_PORT",
		path)
end

----------------------------------------------------------------------------
-- Extract the "directory" and "file" parts of a path
-- @param path String with a path.
-- @return String with the directory part.
-- @return String with the file part.
----------------------------------------------------------------------------
function _M.splitonlast (path, sep)
	local dir,file = match(path,"^(.-)([^:/\\]*)$")
	return dir,file
end

_M.splitpath = _M.splitonlast -- compatibility with previous versions

----------------------------------------------------------------------------
-- Extracts the first and remaining parts of a path
-- @param path separator (defaults to "/")
-- @return String with the extracted part.
-- @return String with the remaining path.
----------------------------------------------------------------------------
function _M.splitonfirst(path, sep)
	local first, rest = match(path, "^/([^:/\\]*)(.*)")
	return first, rest
end

--
-- Define variables and build the cgilua.POST, cgilua.GET tables.
--
local function getparams ()
    local requestmethod = servervariable"REQUEST_METHOD"
	-- Fill in the POST table.
	_M.POST = {}
	if  requestmethod == "POST" then
		post.parsedata {
			read = SAPI.Request.getpostdata,
			discardinput = ap and ap.discard_request_body,
			content_type = _M.servervariable"CONTENT_TYPE",
			content_length = _M.servervariable"CONTENT_LENGTH",
			maxinput = _maxinput,
			maxfilesize = _maxfilesize,
			args = _M.POST,
		}
	end
	-- Fill in the QUERY table.
	_M.QUERY = {}
	urlcode.parsequery (_M.servervariable"QUERY_STRING", _M.QUERY)
end

--
-- Stores all script handlers and the file extensions used to identify
-- them. Loads the default 
local _script_handlers = {}
--
-- Default handler.
-- Sends the contents of the file to the output without processing it.
-- This relies in the browser being able to discover the content type
-- which is not reliable.
-- @param filename String with the name of the file.
--
local function default_handler (filename)
	local fh, err = _open (filename, "rb")
	local contents
	if fh then
		contents = fh:read("*a")
		fh:close()
	else
		error(err)
	end
	_M.header("Content-Lenght", #contents)
	_M.put ("\n")
	_M.put (contents)
end

----------------------------------------------------------------------------
-- Add a script handler.
-- @param file_extension String with the lower-case extension of the script.
-- @param func Function to handle this kind of scripts.
----------------------------------------------------------------------------
function _M.addscripthandler (file_extension, func)
	assert (type(file_extension) == "string", "File extension must be a string")
	if strfind (file_extension, '%.', 1) then
		file_extension = strsub (file_extension, 2)
	end
	file_extension = strlower(file_extension)
	assert (type(func) == "function", "Handler must be a function")

	_script_handlers[file_extension] = func
end

---------------------------------------------------------------------------
-- Obtains the handler corresponding to the given script path.
-- @param path String with a script path.
-- @return Function that handles it or nil.
----------------------------------------------------------------------------
function _M.getscripthandler (path)
	local i,f, ext = strfind (path, "%.([^.]+)$")
	return _script_handlers[strlower(ext or '')]
end

---------------------------------------------------------------------------
-- Execute the given path with the corresponding handler.
-- @param path String with a script path.
-- @return The returned values from the script.
---------------------------------------------------------------------------
function _M.handle (path)
	local h = _M.getscripthandler (path) or default_handler
	return h (path)
end

---------------------------------------------------------------------------
-- Sets "errorhandler" function
-- This function is called by Lua when an error occurs.
-- It receives the error message generated by Lua and it is resposible
-- for the final message which should be returned.
-- @param Function.
---------------------------------------------------------------------------
function _M.seterrorhandler (f)
	local tf = type(f)
	if tf == "function" then
		_errorhandler = f
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

---------------------------------------------------------------------------
-- Defines the "erroroutput" function
-- This function is called to generate the error output.
-- @param Function.
---------------------------------------------------------------------------
function _M.seterroroutput (f)
	local tf = type(f)
	if tf == "function" then
		_erroroutput = f
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

--
-- Stores all close functions in order they are set.
local _close_functions = {
}

---------------------------------------------------------------------------
-- Adds a function to be executed after the script.
-- @param f Function to be registered.
---------------------------------------------------------------------------
function _M.addclosefunction (f)
	local tf = type(f)
	if tf == "function" then
		tinsert (_close_functions, f)
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

--
-- Close function.
--
local function close()
	for i = #_close_functions, 1, -1 do
		_close_functions[i]()
	end
end

--
-- Stores all open functions in order they are set.
local _open_functions = {
}

---------------------------------------------------------------------------
-- Adds a function to be executed before the script.
-- @param f Function to be registered.
---------------------------------------------------------------------------
function _M.addopenfunction (f)
	local tf = type(f)
	if tf == "function" then
		tinsert (_open_functions, f)
	else
		error (format ("Invalid type: expected `function', got `%s'", tf))
	end
end

--
-- Open function.
-- Call all defined open-functions in the order they were created.
--
local function open()
	for i = #_open_functions, 1, -1 do
		_open_functions[i]()
	end
end

--
-- Resets CGILua's state.
--
local function reset ()
	_M.script_path = false
	_M.script_vpath, _M.pdir, _M.use_executable_name, _M.urlpath, _M.script_vdir, _M.script_pdir,
	_M.script_file, _M.authentication, _M.app_name = 
		nil, nil, nil, nil, nil, nil, nil, nil, nil
	_maxfilesize = _default_maxfilesize
	_maxinput = _default_maxinput
	-- Error Handling
	_errorhandler = _default_errorhandler
	_erroroutput = _default_erroroutput
	-- Handlers
	_script_handlers = {}
	_open_functions = {}
	_close_functions = {}
	-- clean temporary files
	for i, v in ipairs(_tmpfiles) do
		_tmpfiles[i] = nil
		v.file:close()
		local _, err = remove(v.name)
		if err then
			error(err)
		end
	end
end

---------------------------------------------------------------------------
-- Request processing.
---------------------------------------------------------------------------
function _M.main ()
	SAPI = _G.SAPI
	buildhandlers()    
	-- Default handler values
	_M.addscripthandler ("lua", _M.doscript)
	_M.addscripthandler ("lp", _M.handlelp)
	-- Looks for an optional loader module
	_M.pcall (function () _G.require"cgilua.loader" end)

	-- post.lua needs to be loaded after cgilua.lua is compiled
	_M.pcall (function () _G.require"cgilua.post" end)

	if _M.loader then
		_M.loader.init()
	end
    
	-- Build QUERY/POST tables
	if not _M.pcall (getparams) then return nil end

	local result
	-- Executes the optional loader module
	if loader then
		loader.run()
	end

	-- Changing curent directory to the script's "physical" dir
	local curr_dir = lfs.currentdir ()
	_M.pcall (function () lfs.chdir (script_pdir) end)

	-- Opening functions
	_M.pcall (open)

	-- Executes the script
	result, err = _M.pcall (function () return handle (script_file) end)
    
	-- Closing functions
	_M.pcall (close)
	-- Changing to original directory
	_M.pcall (function () lfs.chdir (curr_dir) end)

	-- Cleanup
	_M.reset ()
	if result then -- script executed ok!
		return result
	end
end

return _M
