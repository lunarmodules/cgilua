----------------------------------------------------------------------------
-- $Id: cgilua.lua,v 1.1 2003/09/28 23:38:44 tomas Exp $
--
-- Auxiliar functions defined for CGILua scripts
----------------------------------------------------------------------------

require"prep"
require"readuntil"

local Public, Private = {}, {}
cgilua = Public

local tostring = tostring
local error, loadfile, loadstring, xpcall, tonumber, type, unpack = error, loadfile, loadstring, xpcall, tonumber, type, unpack
local write, open, input, read, stderr, tmpfile = io.write, io.open, io.input, io.read, io.stderr, io.tmpfile
local traceback = debug.traceback
local getenv = os.getenv
local getn = table.getn
local format, gsub, strchar, strbyte, strsub, strfind, strlower, strlen = string.format, string.gsub, string.char, string.byte, string.sub, string.find, string.lower, string.len
local min = math.min
local _G = _G
local translate = HTMLPreProcessor.translate
local iterate = iterate

   -- environment for processing multipart/form-data input
Private.boundary = nil    -- boundary string that separates each 'part' of input
Private.maxfilesize = nil -- maximum size for file upload
Private.inputfile = nil   -- temporary file for inputting form-data
Private.bytesleft = nil   -- number of bytes yet to be read

setfenv (1, { __fenv = 1 })

----------------------------------------------------------------------------
-- Read a block of bytes from the current input file.
-- The size of the block is 2^13 or less (the last block).
----------------------------------------------------------------------------
local _read = function ()
	local n = min (Private.bytesleft, 2^13)
	Private.bytesleft = Private.bytesleft - n
	return read (n)
end

----------------------------------------------------------------------------
-- Define the block reader function.
-- This function has two parameters: a delimiter and an output function.
----------------------------------------------------------------------------
Private.read = iterate (_read)

----------------------------------------------------------------------------
-- Extract the boundary string from CONTENT_TYPE metavariable
----------------------------------------------------------------------------
function Private.getboundary ()
  local _,_,boundary = strfind (getenv ("CONTENT_TYPE"), "boundary%=(.-)$")
  return  "--"..boundary 
end

----------------------------------------------------------------------------
-- Create a table containing the headers of a multipart/form-data field
----------------------------------------------------------------------------
function Private.breakheaders (hdrdata)
  local headers = {}
  gsub (hdrdata, '([^%c%s:]+):%s+([^\n]+)', function(type,val)
    type = strlower(type)
    headers[type] = val
  end)
  return headers
end

----------------------------------------------------------------------------
-- Read the headers of the next multipart/form-data field 
--
--  This function returns a table containing the headers values. Each header
--  value is indexed by the corresponding header "type". 
--  If end of input is reached (no more fields to process) it returns nil.
----------------------------------------------------------------------------
function Private.readfieldheaders ()
	local EOH = "\r\n\r\n" -- <CR><LF><CR><LF>
	local hdrdata = ""
	local out = function (str) hdrdata = hdrdata..str end
	if Private.read (EOH, out) then
		-- parse headers
		return Private.breakheaders (hdrdata)
	else
		-- no header found
		return nil
	end
end

----------------------------------------------------------------------------
-- Extract a field name (and possible filename) from its disposition header
----------------------------------------------------------------------------
function Private.getfieldnames (headers)
  local disposition_hdr = headers["content-disposition"]
  local attrs = {}
  if disposition_hdr then
    gsub(disposition_hdr, ';%s*([^%s=]+)="(.-)"', function(attr, val)
	   attrs[attr] = val
         end)
  else
    error("Error processing multipart/form-data."..
          "\nMissing content-disposition header")
  end
  return attrs.name, attrs.filename
end

----------------------------------------------------------------------------
-- Read the contents of a 'regular' field to a string
----------------------------------------------------------------------------
function Private.readfieldcontents ()
	local value = ""
	local boundaryline = "\r\n"..Private.boundary
	local out = function (str) value = value..str end
	if Private.read (boundaryline, out) then
		return value
	else
		error("Error processing multipart/form-data.\nUnexpected end of input")
	end
end

----------------------------------------------------------------------------
-- Read the contents of a 'file' field to a temporary file (file upload)
----------------------------------------------------------------------------
function Private.fileupload (filename)
	-- create a temporary file for uploading the file field
	local file, err = tmpfile()
	if file == nil then
		Private.discardinput(Private.bytesleft)
		error("Cannot create a temporary file.\n"..err)
	end      
	local bytesread = 0
	local boundaryline = "\r\n"..Private.boundary
	local out = function (str)
		local sl = strlen (str)
		if bytesread + sl > Private.maxfilesize then
			Private.discardinput ()
			error (format ("Maximum file size (%d kbytes) exceeded while uploading `%s'", Private.maxfilesize / 1024, filename))
		end
		file:write (str)
		bytesread = bytesread + sl
	end
	if Private.read (boundaryline, out) then
		file:seek ("set", 0)
		return file, bytesread
	else
		error (format ("Error processing multipart/form-data.\nUnexpected end of input while uploading %s", filename))
	end
end

----------------------------------------------------------------------------
-- Compose a file field 'value' 
----------------------------------------------------------------------------
function Private.filevalue (filehandle, filename, filesize, headers)
  -- the temporary file handle
  local value = { file = filehandle,
                  filename = filename,
                  filesize = filesize }
  -- copy additional header values
  for hdr, hdrval in headers do
    if hdr ~= "content-disposition" then
      value[hdr] = hdrval
    end
  end
  return value
end

----------------------------------------------------------------------------
-- Process multipart/form-data 
--
-- This function receives the total size of the incoming multipart/form-data, 
-- the maximum size for a file upload, and a reference to a table where the 
-- form fields should be stored.
--
-- For every field in the incoming form-data a (name=value) pair is 
-- inserted into the given table. [[name]] is the field name extracted
-- from the content-disposition header.
--
-- If a field is of type 'file' (i.e., a 'filename' attribute was found
-- in its content-disposition header) a temporary file is created 
-- and the field contents are written to it. In this case,
-- [[value]] has a table that contains the temporary file handle 
-- (key 'file') and the file name (key 'filename'). Optional headers
-- included in the field description are also inserted into this table,
-- as (header_type=value) pairs.
--
-- If the field is not of type 'file', [[value]] contains the field 
-- contents.
----------------------------------------------------------------------------
function Private.Main (inputsize, args)

	-- create a temporary file for processing input data
	local inputf,err = tmpfile()
	if inputf == nil then
		Private.discardinput(inputsize)
		error("Cannot create a temporary file.\n"..err)
	end

	-- set the environment for processing the multipart/form-data
	Private.inputfile = inputf
	Private.bytesleft = inputsize
	Private.maxfilesize = Private.maxfilesize or inputsize 
	Private.boundary = Private.getboundary()

	while true do
		-- read the next field header(s)
		local headers = Private.readfieldheaders()
		if not headers then break end	-- end of input

		-- get the name attributes for the form field (name and filename)
		local name, filename = Private.getfieldnames(headers)

		-- get the field contents
		local value
		if filename then
			local filehandle, filesize = Private.fileupload(filename)
			value = Private.filevalue(filehandle, filename, filesize, headers)
		else
			value = Private.readfieldcontents()
		end

		-- insert the form field into table [[args]]
		Public.insertfield(args, name, value)
	end
end

----------------------------------------------------------------------------
-- Header functions
----------------------------------------------------------------------------
local header_sent = false

function Public.httpheader (header)
	if not header_sent then
		write (header)
		header_sent = true
	end
end

function Public.contentheader (type, subtype)
	Public.httpheader (format ("Content-type: %s/%s\n\n", type, subtype))
end

function Public.locationheader (url)
	Public.httpheader (format ("Location: %s\n\n", url))
end

function Public.htmlheader ()
	Public.contentheader("text","html")
end

----------------------------------------------------------------------------
-- Function 'put' sends its arguments (basically strings of HTML text)
--  to the server
-- Its basic implementation is to use Lua function 'write', which writes
--  each of its arguments (strings or numbers) to file _OUTPUT (a file
--  handle initialized with the file descriptor for stdout)
----------------------------------------------------------------------------
Public.put = write

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
-- Execute a CGILua script
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
	local f = open(filename)
	if not f then return end    -- no file (or unreadable file)
	f:close()
	return Public.doscript (filename)
end

---------------------------------------------------------------------------
-- Set CGILua's default libraries directory
---------------------------------------------------------------------------
function Public.setlibdir(libdir)
  -- can only be set once (by CGILua's mainscript)
  if Private.libdir then
    error("The default 'libraries directory' cannot be redefined")
  end
  Private.libdir = libdir
end

---------------------------------------------------------------------------
-- Set the maximum "total" input size allowed (in bytes)
---------------------------------------------------------------------------
function Public.setmaxinput(nbytes)
  -- can only be set once (by CGILua's mainscript)
  if Private.maxinput then
    error("Maximum input size redefinition is not allowed")
  end
  Private.maxinput = nbytes
end

---------------------------------------------------------------------------
-- Set the maximum size for an "uploaded" file (in bytes)
--   (can be redefined by a script but "maxinputsize" is checked first)
---------------------------------------------------------------------------
function Public.setmaxfilesize(nbytes)
  Private.maxfilesize = nbytes
end

----------------------------------------------------------------------------
-- Preprocess and include the content of a mixed HTML file into the 
--  currently 'open' HTML document. 
----------------------------------------------------------------------------
function Public.includehtml (filename)
	--if not input(filename) then
		--error("Error opening file '"..filename.."', preprocessing aborted")
		--return
	--end
-- input raises an error so we don't need the above test anymore.
	input (filename)
	local prog = read("*a")
	input()
	prog = translate(prog, "file "..filename)
	if prog then
		local f, err = loadstring (prog, "@"..filename)
		if f then
			return f()
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
	Public.contentheader ("text","html")
	Public.includehtml (filename)
end

----------------------------------------------------------------------------
-- Decode an URL-encoded string (see RFC 2396)
----------------------------------------------------------------------------
function Public.unescape (str)
	str = gsub (str, "+", " ")
	str = gsub (str, "%%(%x%x)", function(h) return strchar(tonumber(h,16)) end)
	str = gsub (str, "\r\n", "\n")
	return str
end

----------------------------------------------------------------------------
-- URL-encode a string (see RFC 2396)
----------------------------------------------------------------------------
function Public.escape (str)
	str = gsub (str, "\n", "\r\n")
	str = gsub (str, "([^%w ])",
		function (c) return format ("%%%02X", strbyte(c)) end)
	str = gsub (str, " ", "+")
	return str
end

----------------------------------------------------------------------------
-- Insert a (name=value) pair into table [[args]]
----------------------------------------------------------------------------
function Public.insertfield (args, name, value)
  if not args[name] then
    args[name] = value
  else
    args[name] = args[name]..","..value
  end
end

----------------------------------------------------------------------------
-- Parse url-encoded request data 
--   (the query part of the script URL or url-encoded post data)
--
--  Each decoded (name=value) pair is inserted into table [[args]]
----------------------------------------------------------------------------
function Public.parsequery (query, args)
  if type(query) == "string" then
    local insertfield, unescape = Public.insertfield, Public.unescape
    gsub(query,"([^&=]+)=([^&=]*)&?",
       	      function(key,val)
		insertfield(args,unescape(key),unescape(val))
	      end)
  end
end

----------------------------------------------------------------------------
-- URL-encode the elements of a table creating a string to be used in a
--   URL for passing data/parameters to another script
----------------------------------------------------------------------------
function Public.encodetable (args)
  if args == nil or next(args) == nil then   -- no args or empty args?
    return ""
  end
  local strp = ""
  for key,val in args do
    strp = strp.."&"..Public.escape(key).."="..Public.escape(val)
  end
  -- remove first & 
  return strsub(strp,2)
end

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
function Public.mkabsoluteurl (path)
	return format("http://%s:%s%s",
		getenv("SERVER_NAME"),
		getenv("SERVER_PORT"),
		path)
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
-- Extract the "directory" and "file" parts of a path
----------------------------------------------------------------------------
function Public.splitpath (path)
	local _,_,dir,file = strfind(path,"^(.-)([^:/\\]*)$")
	return dir,file
end

----------------------------------------------------------------------------
-- Given a script path, this function extracts its "file" part and returns 
--  the script type (defined by the file extension), coded as a string. 
-- The possible results are "lua", "html" and "other"
----------------------------------------------------------------------------
function Public.getscripttype (path)
  local _,file = Public.splitpath(path)
  file = strlower(file)
  if strfind(file,"%.html?$") then
    return "html"
  elseif strfind(file,"%.lua$") then
    return "lua"
  else
    return "other"
  end
end

----------------------------------------------------------------------------
-- Stores all script handlers and the file extensions used to identify
-- them.
Private.script_handlers = {
	htm = Public.preprocess,
	html = Public.preprocess,
	lua = Public.doscript,
}

----------------------------------------------------------------------------
-- Add a script handler.
-- @param file_extension String with the lower-case extension of the script.
-- @param func Function to handle this kind of scripts.
----------------------------------------------------------------------------
function Public.addscripthandler (file_extension, func)
	assert (type(file_extension) == "string", "File extension must be a string")
	assert (type(func) == "function", "Handler must be a function")
	Private.script_handlers[file_extension] = func
end

----------------------------------------------------------------------------
-- Obtains the handler corresponding to the given script path.
-- @param path String with a script path.
-- @return Function that handles it or nil.
----------------------------------------------------------------------------
function Public.getscripthandler (path)
	local _, file = Public.splitpath (path)
	local i,f, ext = strfind (file, "%.([^.]+)$")
	return Private.script_handlers[strlower(ext or '')]
end

----------------------------------------------------------------------------
-- Read (discarding) the incoming POST REQUEST data 
----------------------------------------------------------------------------
function Private.discardinput (inputsize)
--[[
  local blocklen = 8192
  local s
  while inputsize > 0 do
    blocklen = math.min(blocklen, inputsize)
    s = read(blocklen)
    if s == nil then break end
    inputsize = inputsize - strlen(s)
  end
--]]
	Private.read ('\0', function()end)
end

----------------------------------------------------------------------------
-- Parse the POST REQUEST incoming data according to its "content type"
-- as defined by the metavariable CONTENT_TYPE (RFC CGI)
--
--  An error is issued if the "total" size of the incoming data
--   (defined by the metavariable CONTENT_LENGTH) exceeds the
--   maximum input size allowed
----------------------------------------------------------------------------
function Public.parsepostdata (args)
  -- get the "total" size of the incoming data
  local inputsize = tonumber(getenv("CONTENT_LENGTH"))
  if inputsize > Private.maxinput then
    -- some Web Servers (like IIS) require that all the incoming data is read 
    Private.discardinput(inputsize)
    error(format("Total size of incoming data (%d KB) exceeds configured maximum (%d KB)",
	         inputsize /1024, Private.maxinput / 1024))
  end

  -- process the incoming data according to its content type
  local contenttype = getenv("CONTENT_TYPE")
  if not contenttype then
    error("Undefined Media Type") 
  end
  if strfind(contenttype, "x%-www%-form%-urlencoded") then
    Public.parsequery(read(inputsize),args)
  elseif strfind(contenttype, "multipart/form%-data") then
		Private.Main (inputsize, args)
  else
    error("Unsupported Media Type: "..contenttype)
  end
end

---------------------------------------------------------------------------
-- Generic function creator to set a Private member function.
-- @param member String with the name of the Private's member.
-- @return Function that check the type of its parameter and assigns it
--	as Private[member].
---------------------------------------------------------------------------
function Private.G_setprivate (member)
	return function (f)
		local tf = type(f)
		if tf == "function" then
			Private[member] = f
		else
			error(format("Invalid type: expected `function', got `%s'", tf))
		end
	end
end

---------------------------------------------------------------------------
-- Set CGILua's "errorhandler" function
--
-- This function will be called with the original error message and its
-- return value will be propageted
---------------------------------------------------------------------------
Public.seterrorhandler = Private.G_setprivate ("errorhandler")
Public.seterrorhandler (traceback)

---------------------------------------------------------------------------
-- Set CGILua's "erroroutput" function
--
-- This function will be called to output the error message.
---------------------------------------------------------------------------
Public.seterroroutput = Private.G_setprivate ("erroroutput")
Public.seterroroutput (function (msg)
	Public.httpheader("text", "plain")
	Public.put ("There was an error.\nProper information was written to the error log.")
end)

---------------------------------------------------------------------------
-- Set CGILua's "errorlog" function
--
-- This function will be called to log the error message.
---------------------------------------------------------------------------
Public.seterrorlog = Private.G_setprivate ("errorlog")
Public.seterrorlog (function (msg)
	stderr:write (msg)
end)

---------------------------------------------------------------------------
-- Execute a function with an error handler.
---------------------------------------------------------------------------
function Public.pcall (f, ...)
	local ok, errmsg = xpcall (function () return f(unpack(arg)) end,
		Private.errorhandler)
	if not ok then
		Private.errorlog (errmsg)
		Private.erroroutput (errmsg)
	end
end

---------------------------------------------------------------------------
-- Set CGILua's "close" function
--
-- This function will be called after the user script execution
---------------------------------------------------------------------------
Public.setclosefunction = Private.G_setprivate ("closefunction")

function Public.close()
  if Private.closefunction then
    Private.closefunction()
  end
end
