----------------------------------------------------------------------------
-- CGILua library.
--
-- @release $Id: cgilua.lua,v 1.85 2009/06/28 22:42:34 tomas Exp $
----------------------------------------------------------------------------

local urlcode = require"cgilua.urlcode"
local lp = require"cgilua.lp"
local lfs = require"lfs"
local debug = require"debug"
local assert, error, ipairs, select, tostring, type, xpcall = assert, error, ipairs, select, tostring, type, xpcall
local unpack = table.unpack or unpack
local pairs = pairs
local gsub, format, strfind, strlower, strsub, match = string.gsub, string.format, string.find, string.lower, string.sub, string.match
local setmetatable = setmetatable
local _open = io.open
local tinsert, tremove, concat = table.insert, table.remove, table.concat
local date = os.date
local os_tmpname = os.tmpname
local getenv = os.getenv
local remove = os.remove
lp.setoutfunc ("cgilua.put")
lp.setcompatmode (true)

-- Module return in first require
local cgilua = {
	_COPYRIGHT = "Copyright (C) 2003-2009 Kepler Project; Copyright (C) 2010-2022 The CGILua Authors.",
	_DESCRIPTION = "CGILua is a tool for creating dynamic Web pages and manipulating input data from forms",
	_VERSION = "CGILua 6.0",
}

-- local functions and variables
local L = { 

}


local function build_library_objects(enviroment, response)
	local M = {
		_COPYRIGHT = cgilua._COPYRIGHT,
		_DESCRIPTION = cgilua._DESCRIPTION,
		_VERSION = cgilua._VERSION,
	}
	--[[
	######################################################################
	######################################################################
	###################### Public ########################################
	######################################################################
	######################################################################
	]]

	---------------------------------------------------------------------------
	-- gets an enviroment variable
	---------------------------------------------------------------------------
	M.servervariable = function (name)
		return enviroment[name] 
	end;

	---------------------------------------------------------------------------
	-- Build Response table
	---------------------------------------------------------------------------
	M.Response = {
		contenttype = function (header)
			response:content_type(header)
		end,
		errorlog = function (msg, errlevel)
			enviroment.error:write (msg)
		end,
		header = function (header, value)
			if response.headers[header] then
				if type(response.headers[header]) == "table" then
					table.insert(response.headers[header], value)
				else
					response.headers[header] = { response.headers[header], value }
				end
			else
				response.headers[header] = value
			end
		end,
		redirect = function (url)
			response.status = 302
			response.headers["Location"] = url
		end,
		status = response.status,
		write = function (...)
			response:write({...})
		end,
	}

	---------------------------------------------------------------------------
	-- set response status
	---------------------------------------------------------------------------
	M.setstatus = function (st)
		response.status = st
	end

	---------------------------------------------------------------------------
	-- Adds a function to be executed before the script.
	-- @param f Function to be registered.
	---------------------------------------------------------------------------
	M.addopenfunction = function (f)
		local tf = type(f)
		if tf == "function" then
			tinsert (L._open_functions, f)
		else
			error (format ("Invalid type: expected `function', got `%s'", tf))
		end
	end

	---------------------------------------------------------------------------
	-- Adds a function to be executed after the script.
	-- @param f Function to be registered.
	---------------------------------------------------------------------------
	M.addclosefunction = function (f)
		local tf = type(f)
		if tf == "function" then
			tinsert (L._close_functions, f)
		else
			error (format ("Invalid type: expected `function', got `%s'", tf))
		end
	end

	----------------------------------------------------------------------------
	-- Add a script handler.
	-- @param file_extension String with the lower-case extension of the script.
	-- @param func Function to handle this kind of scripts.
	----------------------------------------------------------------------------
	M.addscripthandler = function (file_extension, func)
		assert (type(file_extension) == "string", "File extension must be a string")
		if strfind(file_extension, '%.') then
			file_extension = strsub (file_extension, 2)
		end
		file_extension = strlower(file_extension)
		assert (type(func) == "function", "Handler must be a function")

		L._script_handlers[file_extension] = func
	end

	---------------------------------------------------------------------------
	-- Obtains the handler corresponding to the given script path.
	-- @param path String with a script path.
	-- @return Function that handles it or nil.
	----------------------------------------------------------------------------
	M.getscripthandler = function (path)
		local ext = match(path, "%.([^.]+)$")
		return L._script_handlers[strlower(ext or '')]
	end

	---------------------------------------------------------------------------
	-- Execute the given path with the corresponding handler.
	-- @param path String with a script path.
	-- @return The returned values from the script.
	---------------------------------------------------------------------------
	M.handle = function (path)
		local h = M.getscripthandler (path) or default_handler
		return h (path)
	end

	---------------------------------------------------------------------------
	-- Sets "errorhandler" function
	-- This function is called by Lua when an error occurs.
	-- It receives the error message generated by Lua and it is resposible
	-- for the final message which should be returned.
	-- @param f Function.
	---------------------------------------------------------------------------
	M.seterrorhandler = function (f)
		local tf = type(f)
		if tf == "function" then
			L.errorhandler = f
		else
			error (format ("Invalid type: expected `function', got `%s'", tf))
		end
	end

	---------------------------------------------------------------------------
	-- Defines the "erroroutput" function
	-- This function is called to generate the error output.
	-- @param f Function.
	---------------------------------------------------------------------------
	M.seterroroutput = function (f)
		local tf = type(f)
		if tf == "function" then
			L.erroroutput = f
		else
			error (format ("Invalid type: expected `function', got `%s'", tf))
		end
	end


	---------------------------------------------------------------------------
	-- Returns a temporary file in a directory using a name generator
	-- @param dir Base directory for the temporary file
	-- @param namefunction Name generator function
	---------------------------------------------------------------------------
	M.tmpfile = function (dir, namefunction)
		dir = dir or M.tmp_path
		namefunction = namefunction or M.tmpname
		local tempname = namefunction()
		local filename = dir.."/"..tempname
		local file, err = _open(filename, "w+b")
		if file then
			tinsert(L._tmpfiles, {name = filename, file = file})
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
	M.handlelp = function  (filename, env)
		env = env or L.buildscriptenv()
		M.htmlheader ()
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
	M.buildplainhandler = function (type, subtype)
		return function (filename)
			local fh, err = _open (filename, "rb")
			local contents = ""
			if fh then
				contents = fh:read("*a")
				fh:close()
			else
				error(err)
			end
			M.header("Content-Lenght", #contents)
			M.contentheader (type, subtype)
			M.put (contents)
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
	M.buildprocesshandler = function  (type, subtype)
		return function (filename)
			local env = L.buildscriptenv()
			M.contentheader (type, subtype)
			lp.include (filename, env)
		end
	end

	----------------------------------------------------------------------------
	-- Create an URL path to be used as a link to a CGILua script
	-- @param script String with the name of the script.
	-- @param args Table with arguments to script (optional).
	-- @return String in URL format.
	----------------------------------------------------------------------------
	M.mkurlpath = function (script, args)
		-- URL-encode the parameters to be passed do the script
		local params = ""
		if args then
			params = "?"..urlcode.encodetable(args)
		end
		if strsub(script,1,1) == '/' or M.script_vdir == '/' then
			return script .. params
		else
			return M.script_vdir .. script .. params
		end
	end

	----------------------------------------------------------------------------
	-- Create an absolute URL containing the given URL path
	-- @param path String with the path.
	-- @param protocol String with the name of the protocol (default = "http").
	-- @return String in URL format.
	----------------------------------------------------------------------------
	M.mkabsoluteurl = function  (path, protocol)
		protocol = protocol or "http"
		if path:sub(1,1) ~= '/' then
			path = '/'..path
		end
		return format("%s://%s:%s%s",
			protocol,
			M.servervariable"SERVER_NAME",
			M.servervariable"SERVER_PORT",
			path)
	end

	----------------------------------------------------------------------------
	-- Extract the "directory" and "file" parts of a path
	-- @param path String with a path.
	-- @return String with the directory part.
	-- @return String with the file part.
	----------------------------------------------------------------------------
	M.splitonlast = function  (path)
		local dir,file = match(path,"^(.-)([^:/\\]*)$")
		return dir,file
	end

	M.splitpath = M.splitonlast -- compatibility with previous versions

	----------------------------------------------------------------------------
	-- Extracts the first and remaining parts of a path
	-- @return String with the extracted part.
	-- @return String with the remaining path.
	----------------------------------------------------------------------------
	M.splitonfirst = function (path)
		local first, rest = match(path, "^/([^:/\\]*)(.*)")
		return first, rest
	end


	----------------------------------------------------------------------------
	-- Execute a script
	--  If an error is found, Lua's error handler is called and this function
	--  does not return
	-- @param filename String with the name of the file to be processed.
	-- @return The result of the execution of the file.
	----------------------------------------------------------------------------
	M.doscript = function (filename)
		local env = L.buildscriptenv()
		local f, err = loadfile(filename, "bt", env)
		if not f then
			error (format ("Cannot execute `%s'. Exiting.\n%s", filename, err))
		else
			if _VERSION == "Lua 5.1" then
				setfenv(f, env)
			end
			return M.pcall(f)
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
	M.doif = function (filename)
	        if not filename then return end    -- no file
	        local f, err = _open(filename)
	        if not f then return nil, err end    -- no file (or unreadable file)
	        f:close()
	        return M.doscript (filename)
	end

	---------------------------------------------------------------------------
	-- Set the maximum "total" input size allowed (in bytes)
	-- @param nbytes Number of the maximum size (in bytes) of the whole POST data.
	---------------------------------------------------------------------------
	M.setmaxinput = function(nbytes)
	        L.maxinput = nbytes
	end

	---------------------------------------------------------------------------
	-- Set the maximum size for an "uploaded" file (in bytes)
	-- Might be less or equal than L.maxinput.
	-- @param nbytes Number of the maximum size (in bytes) of a file.
	---------------------------------------------------------------------------
	M.setmaxfilesize = function(nbytes)
	        L.maxfilesize = nbytes
	end

	---------------------------------------------------------------------------
	-- Default path for temporary files
	---------------------------------------------------------------------------
	M.tmp_path = CGILUA_TMP or getenv("TEMP") or getenv ("TMP") or "/tmp"

	---------------------------------------------------------------------------
	-- Default function for temporary names
	-- @return a temporay name using os.tmpname
	---------------------------------------------------------------------------
	M.tmpname = function ()
	    local tempname = os_tmpname()
	    -- Lua os.tmpname returns a full path in Unix, but not in Windows
	    -- so we strip the eventual prefix
	    tempname = gsub(tempname, "(/tmp/)", "")
	    return tempname
	end

	----------------------------------------------------------------------------
	-- Sends a header.
	-- @name header
	-- @class function
	-- @param header String with the header.
	-- @param value String with the corresponding value.
	----------------------------------------------------------------------------
	M.header = function (...)
		return M.Response.header (...)
	end

	----------------------------------------------------------------------------
	-- Sends a Content-type header.
	-- @param type String with the type of the header.
	-- @param subtype String with the subtype of the header.
	----------------------------------------------------------------------------
	M.contentheader = function (type, subtype)
		M.Response.contenttype (type..'/'..subtype)
	end

	----------------------------------------------------------------------------
	-- Sends the HTTP header "text/html".
	----------------------------------------------------------------------------
	M.htmlheader = function ()
		M.Response.contenttype ("text/html")
	end

	----------------------------------------------------------------------------
	-- Sends an HTTP header redirecting the browser to another URL
	-- @param url String with the URL.
	-- @param args Table with the arguments (optional).
	----------------------------------------------------------------------------
	M.redirect = function (url, args)
		if strfind(url,"^https?:") then
			local params=""
			if args then
				params = "?"..urlcode.encodetable(args)
			end
			return M.Response.redirect(url..params)
		else
			local protocol = (M.servervariable"SERVER_PORT" == "443") and "https" or "http"
			return M.Response.redirect(M.mkabsoluteurl(M.mkurlpath(url,args), protocol))
		end
	end

	----------------------------------------------------------------------------
	-- Primitive error output function
	-- @param msg String (or number) with the message.
	-- @param level String with the error level (optional).
	----------------------------------------------------------------------------
	M.errorlog = function (msg, level)
		local t = type(msg)
		if t == "string" or t == "number" then
			M.Response.errorlog (msg, level)
		else
			error ("bad argument #1 to `cgilua.errorlog' (string expected, got "..t..")", 2)
		end
	end

	----------------------------------------------------------------------------
	-- Converts all its arguments to strings before sending them to the server.
	----------------------------------------------------------------------------
	M.print = function (...)
		local args = { ... }
		for i = 1, select("#",...) do
			args[i] = tostring(args[i])
		end
		M.Response.write (concat(args,"\t"))
		M.Response.write ("\n")
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
	M.put = function (...)
		return M.Response.write (...)
	end

	----------------------------------------------------------------------------
	-- Returns the current errorhandler
	----------------------------------------------------------------------------
	M._geterrorhandler = function(msg)
		return L.errorhandler(msg)
	end

	----------------------------------------------------------------------------
	-- Executes a function using the CGILua error handler.
	-- @param f Function to be called.
	----------------------------------------------------------------------------
	M.pcall = function (f)
		local results = {xpcall (f, L.errorhandler)}
		local ok = results[1]
		tremove(results, 1)
		if ok then
			if #results == 0 then results = { true } end
			return unpack(results)
		else
			L.erroroutput (unpack(results))
		end
	end


	--[[
	######################################################################
	######################################################################
	###################### Local #########################################
	######################################################################
	######################################################################
	]]

	----------------------------------------------------------------------
	-- Internal state variables.
	----------------------------------------------------------------------
	L.default_errorhandler = debug.traceback
	L.errorhandler = L.default_errorhandler
	L.default_erroroutput = function (msg)
		if type(msg) ~= "string" and type(msg) ~= "number" then
			msg = format ("bad argument #1 to 'error' (string expected, got %s)", type(msg))
		end
	  
		-- Logging error
		M.Response.errorlog (msg)
		M.Response.errorlog (" ")

		M.Response.errorlog (M.servervariable"REMOTE_ADDR")
		M.Response.errorlog (" ")

		M.Response.errorlog (date())
		M.Response.errorlog ("\n")

		-- Building user message
		msg = gsub (gsub (msg, "\n", "<br>\n"), "\t", "&nbsp;&nbsp;")
		M.Response.contenttype ("text/html")
		M.Response.write ("<html><head><title>CGILua Error</title></head><body>" .. msg .. "</body></html>")
	end
	L.erroroutput = L.default_erroroutput
	L.default_maxfilesize = 512 * 1024
	L.maxfilesize = L.default_maxfilesize
	L.default_maxinput = 1024 * 1024
	L.maxinput = L.default_maxinput
	L.script_path = false

	----------------------------------------------------------------------
	-- Define variables and build the cgilua.POST and cgilua.GET tables.
	----------------------------------------------------------------------
	L.getparams = function()
	    local requestmethod = M.servervariable"REQUEST_METHOD"
		-- Fill in the POST table.
		M.POST = {}
		if  requestmethod == "POST" then
			M.post.parsedata {
				read = function (n) return enviroment.input:read(n) end;
				discardinput = ap and ap.discard_request_body,
				content_type = M.servervariable"CONTENT_TYPE",
				content_length = M.servervariable"CONTENT_LENGTH",
				maxinput = L.maxinput,
				maxfilesize = L.maxfilesize,
				args = M.POST,
			}
		end
		-- Fill in the QUERY table.
		M.QUERY = {}
		urlcode.parsequery (M.servervariable"QUERY_STRING", M.QUERY)
	end

	----------------------------------------------------------------------------
	-- Builds the default handler table from cgilua.mime
	----------------------------------------------------------------------------
	L.buildhandlers = function()
		local mime = require "cgilua.mime"
		for ext, mediatype in pairs(mime) do
			local t, st = match(mediatype, "([^/]*)/([^/]*)")
			M.addscripthandler(ext, M.buildplainhandler(t, st))
		end
	end

	----------------------------------------------------------------------
	--
	----------------------------------------------------------------------
	L.buildscriptenv = function()
		local env = { cgilua = M, print = M.print, write = M.put }
		setmetatable(env, { __index = _G, __newindex = _G })
		return env
	end

	----------------------------------------------------------------------
	--
	----------------------------------------------------------------------
	L._tmpfiles = { }

	----------------------------------------------------------------------
	-- Stores all script handlers and the file extensions used to identify
	-- them. Loads the default 
	----------------------------------------------------------------------
	L._script_handlers = { }

	----------------------------------------------------------------------
	-- Default handler.
	-- Sends the contents of the file to the output without processing it.
	-- This relies in the browser being able to discover the content type
	-- which is not reliable.
	-- @param filename String with the name of the file.
	----------------------------------------------------------------------
	L.default_handler = function (filename)
		local fh, err = _open (filename, "rb")
		local contents
		if fh then
			contents = fh:read("*a")
			fh:close()
		else
			error(err)
		end
		M.header("Content-Lenght", #contents)
		M.put ("\n")
		M.put (contents)
	end

	----------------------------------------------------------------------
	-- Stores all close functions in order they are set.
	----------------------------------------------------------------------
	L._close_functions = {
	}

	----------------------------------------------------------------------
	-- Close function.
	----------------------------------------------------------------------
	L.close = function ()
		for i = #L._close_functions, 1, -1 do
			L._close_functions[i]()
		end
	end

	----------------------------------------------------------------------
	-- Stores all open functions in order they are set.
	----------------------------------------------------------------------
	L._open_functions = {
	}

	----------------------------------------------------------------------
	-- Open function.
	-- Call all defined open-functions in the order they were created.
	----------------------------------------------------------------------
	L.open = function ()
		for i = #L._open_functions, 1, -1 do
			L._open_functions[i]()
		end
	end

	----------------------------------------------------------------------
	-- Resets CGILua's state.
	----------------------------------------------------------------------
	L.reset = function  ()
		L.script_path = false
		M.script_vpath, M.pdir, M.use_executable_name, M.urlpath, M.script_vdir, M.script_pdir,
		M.script_file, M.authentication, M.app_name = 
			nil, nil, nil, nil, nil, nil, nil, nil, nil
		L.maxfilesize = L.default_maxfilesize
		L.maxinput = L.default_maxinput
		-- Error Handling
		L.errorhandler = L.default_errorhandler
		L.erroroutput = L.default_erroroutput
		-- Handlers
		L._script_handlers = {}
		L._open_functions = {}
		L._close_functions = {}
		-- clean temporary files
		for i, v in ipairs(L._tmpfiles) do
			L._tmpfiles[i] = nil
			v.file:close()
			local _, err = remove(v.name)
			if err then
				error(err)
			end
		end
		M.Response = nil;
	end

	return M;
end


---------------------------------------------------------------------------
-- Request processing.
-- env: enviroment variables
-- response: the response object
---------------------------------------------------------------------------
function cgilua.main (enviroment, response)
	--validade response parameter
	assert(type(response) == "table", "invalid parameter: response")
	assert(response.content_type, "invalid parameter: response need to have a method content_type()")
	assert(response.write, "invalid parameter: response need to have a method write()")
	assert(response.headers, "invalid parameter: response need to have a atribute headers")
	assert(response.status, "invalid parameter: response need to have a atribute status")

	-- enviroment variables
	_G.CGILUA_APPS = _G.CGILUA_APPS or enviroment.DOCUMENT_ROOT .. "/cgilua"
	_G.CGILUA_CONF = _G.CGILUA_CONF or enviroment.DOCUMENT_ROOT .. "/cgilua"
	_G.CGILUA_TMP = _G.CGILUA_TMP or os.getenv("TMP") or os.getenv("TEMP") or "/tmp"
	_G.CGILUA_ISDIRECT = true

	-- build library objects
    local M = build_library_objects (enviroment, response);
    package.loaded.cgilua = M;

    -- Main function
	L.buildhandlers()
	-- Default handler values
	M.addscripthandler ("lua", M.doscript)
	M.addscripthandler ("lp", M.handlelp)
	-- Looks for an optional loader module
	M.pcall (function () M.loader = require"cgilua.loader" end)

	-- post.lua needs to be loaded after cgilua.lua is compiled
	M.pcall (function () M.post = require"cgilua.post" end)

	if M.loader then
		M.loader.init()
	end
    
	-- Build QUERY/POST tables
	if not M.pcall (L.getparams) then return nil end

	-- Executes the optional loader module
	if M.loader then
		M.loader.run()
	end

	-- Changing curent directory to the script's "physical" dir
	local curr_dir = lfs.currentdir ()
	M.pcall (function () lfs.chdir (M.script_pdir) end)

	-- Opening functions
	M.pcall (L.open)

	-- Executes the script
	-- "return" is not used anywhere
	M.pcall (function () return M.handle (M.script_file) end)
    
	-- Closing functions
	M.pcall (L.close)
	-- Changing to original directory
	M.pcall (function () lfs.chdir (curr_dir) end)

	-- Cleanup
	L.reset ()
	
	return response:finish();
end

return cgilua
