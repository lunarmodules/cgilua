----------------------------------------------------------------------------
-- $Id: auxiliar.lua,v 1.5 2003/08/05 14:59:00 tomas Exp $
--
-- Auxiliar functions defined for CGILua scripts
----------------------------------------------------------------------------

local Public, Private = {}, {}
cgilua = Public

local dofile = dofile
local error = error
local _G = _G
local io = io
local loadfile = loadfile
local loadstring = loadstring
local os = os
local pcall = pcall
local require = require
local table = table
local tonumber = tonumber
local translate = HTMLPreProcessor.translate
local type = type
local string = string
setfenv (1, { __fenv = 1 })

----------------------------------------------------------------------------
-- Auxiliar functions defined in C
----------------------------------------------------------------------------
function Public.httpheader (header)
	io.write (header)
end

function Public.contentheader (type, subtype)
	io.write (string.format ("Content-type: %s/%s\n\n", type, subtype))
end

function Public.locationheader (url)
	io.write (string.format ("Location: %s\n\n", url))
end

----------------------------------------------------------------------------
-- Function 'put' sends its arguments (basically strings of HTML text)
--  to the server
-- Its basic implementation is to use Lua function 'write', which writes
--  each of its arguments (strings or numbers) to file _OUTPUT (a file
--  handle initialized with the file descriptor for stdout)
----------------------------------------------------------------------------
Public.put = io.write

----------------------------------------------------------------------------
-- Remove globals not allowed in CGILua scripts
----------------------------------------------------------------------------
function Public.removeglobals (notallowed)
  for i=1,table.getn(notallowed) do
    local g = notallowed[i]
    if type(_G[g]) == "function" then
      _G[g] = function()
                     error("Function '"..g..
                           "' is not allowed in CGILua scripts.")
                   end
    else
      _G[g] = nil
    end
  end
end

----------------------------------------------------------------------------
-- Load (execute) the content of a file as a Lua chunk
-- If the execution is successful, this function returns a non-nil value
--   (results returned by the chunk are discarded)
-- If an error is found, this function returns nil and a string describing
--  the error (returned by Lua function 'dofile'). If a "file error" ocurred,
--  a string describing this error is also returned.
----------------------------------------------------------------------------
function Public.loadfile (filename)
	local f, err = io.open(filename)
	if not f then	-- no file (or unreadable file)
		return nil, err
	end
	f:close()
	local res, err = loadfile(filename)
	if not res then
		error(string.format("Cannot execute '%s': %s. Exiting.",filename, err))
	end
	return res() or true  -- run file
end

----------------------------------------------------------------------------
-- Execute a CGILua script
--  If an error is found, Lua's error handler is called and this function
--  does not return
----------------------------------------------------------------------------
function Public.doscript (filename)
  local res,err,strerr = Public.loadfile(filename)
  if not res then
    error(string.format("Cannot execute script '%s'. Exiting.\n%s",filename,(strerr or "")))
  end
end

----------------------------------------------------------------------------
-- Execute the file that configures a CGILua script environment
--  If an error is found, and it is not a "file error", Lua 'error'
--  is called and this function does not return
----------------------------------------------------------------------------
function Public.doenv (filename)
	local f = io.open(filename)
	if not f then return end    -- no file (or unreadable file)
	f:close()
	local res = loadfile(filename)
	if not res then
		error(string.format("Cannot execute '%s'. Exiting.",filename))
	end
	res()  -- run file
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
-- Set CGILua's 'authorized libs' information
---------------------------------------------------------------------------
function Public.setauthlibs(authlibs)
  -- can only be set once (by CGILua's mainscript)
  if Private.authorizedLibs then
    error("Authorized libraries information cannot be redefined")
  end
  Private.authorizedLibs = authlibs
end

---------------------------------------------------------------------------
-- Load an authorized CGILua extension (dynamic library and/or lua file)
----------------------------------------------------------------------------

--[[
function Public.loadlibrary (lib)
  local libdesc = Private.authorizedLibs[lib]
  if not libdesc then
    error("Error loading '"..lib.."': not an authorized library.")
  end

  -- test if library is already loaded
  if not libdesc.loaded then
    libdesc.loaded = "yes"

    -- load dynamic library, if defined
    if libdesc.dyn then
      local libhandle, err = loadlib(libdesc.dyn.libname,
                                      (libdesc.dyn.libdir or Private.libdir))
      if not libhandle then
        error(format("Error loading library '%s': cannot load '%s'.\n%s",
                     lib,libdesc.dyn.libname,err))
      end
      callfromlib(libhandle, libdesc.dyn.init)
    end

    -- load (do) lua file, if defined
    if libdesc.lua then
      local libpath = (libdesc.lua.libdir or Private.libdir)..libdesc.lua.libname
      local res,err,strerr = Public.loadfile(libpath)
      if not res then
        error(format("Error loading library '%s': cannot execute '%s'.\n%s",
                       lib,libpath,(strerr or "")))
      end
    end
  end
end  
--]]

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
	if not io.input(filename) then
		error("Error opening file '"..filename.."', preprocessing aborted")
		return
	end
	local prog = io.read("*a")
	io.input()
	prog = translate(prog, "file "..filename)
	if prog then
		local f, err = loadstring (prog, "@"..filename)
		if f then
			return pcall (f)
		end
	end
end

----------------------------------------------------------------------------
-- Preprocess the content of a mixed HTML file and output a complete
--   HTML document ( a 'Content-type' header is inserted before the
--   preprocessed HTML )
----------------------------------------------------------------------------
function Public.preprocess (filename)
  Public.contentheader("text","html")
  Public.includehtml(filename)
end

----------------------------------------------------------------------------
-- Decode an URL-encoded string (see RFC 2396)
----------------------------------------------------------------------------
function Public.unescape (str)
  local dstr = string.gsub(string.gsub(string.gsub(str,"+"," "),
                         "%%(%x%x)",
                         function(hex) 
                           return string.char(tonumber(hex,16))
                         end),
                     "\r\n","\n")
  return dstr
end

----------------------------------------------------------------------------
-- URL-encode a string (see RFC 2396)
----------------------------------------------------------------------------
function Public.escape (str)
  local estr = string.gsub(string.gsub(string.gsub(str,"\n","\r\n"),
                         "([^%w ])",
			 function(c) 
                           return string.format("%%%02X", string.byte(c))
                         end),
                    " ","+")
  return estr
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
    string.gsub(query,"([^&=]+)=([^&=]*)&?",
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
  return string.sub(strp,2)
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
  if string.sub(script,1,1) == "/" then
    return Public.urlpath .. script .. params
  else
    return Public.urlpath .. Public.script_vdir .. script .. params
  end
end

----------------------------------------------------------------------------
-- Create an absolute URL containing the given URL path
----------------------------------------------------------------------------
function Public.mkabsoluteurl (path)
	return string.format("http://%s:%s%s",
		os.getenv("SERVER_NAME"),
		os.getenv("SERVER_PORT"),
		path)
end

----------------------------------------------------------------------------
-- Create an HTTP header redirecting the browser to another URL
----------------------------------------------------------------------------
function Public.redirect (url, args)
  if string.find(url,"http:") then
    local params=""
    if args then
      params = "?"..Public.encodetable(args)
    end
    Public.locationheader(url..params)
  else
    local abs_url = Public.mkabsoluteurl(Public.mkurlpath(url,args))
    Public.locationheader(abs_url)
  end
end

----------------------------------------------------------------------------
-- Output an HTML header
----------------------------------------------------------------------------
function Public.htmlheader ()
  Public.contentheader("text","html")
end

----------------------------------------------------------------------------
-- Extract the "directory" and "file" parts of a path
----------------------------------------------------------------------------
function Public.splitpath (path)
  local _,_,dir,file = string.find(path,"^(.-)([^:/\\]*)$")
  return dir,file
end

----------------------------------------------------------------------------
-- Given a script path, this function extracts its "file" part and returns 
--  the script type (defined by the file extension), coded as a string. 
-- The possible results are "lua", "html" and "other"
----------------------------------------------------------------------------
function Public.getscripttype (path)
  local _,file = Public.splitpath(path)
  file = string.lower(file)
  if string.find(file,"%.html?$") then
    return "html"
  elseif string.find(file,"%.lua$") then
    return "lua"
  else
    return "other"
  end
end

----------------------------------------------------------------------------
-- Stores all script handlers and the file extensions used to identificate
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
	local i,f, ext = string.find (file, "%.([^.]+)$")
	return Private.script_handlers[string.lower(ext or '')]
end

----------------------------------------------------------------------------
-- Read (discarding) the incoming POST REQUEST data 
----------------------------------------------------------------------------
function Public.discardinput (inputsize)
  local blocklen = 8192
  local s
  while inputsize > 0 do
    blocklen = math.min(blocklen, inputsize)
    s = io.read(blocklen)
    if s == nil then break end
    inputsize = inputsize - string.len(s)
  end
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
  local inputsize = tonumber(os.getenv("CONTENT_LENGTH"))
  if inputsize > Private.maxinput then
    -- some Web Servers (like IIS) require that all the incoming data is read 
    Public.discardinput(inputsize)
    error(format("Total size of incoming data (%d KB) exceeds configured maximum (%d KB)",
	         inputsize /1024, Private.maxinput / 1024))
  end

  -- process the incoming data according to its content type
  local contenttype = os.getenv("CONTENT_TYPE")
  if not contenttype then
    error("Undefined Media Type") 
  end
  if string.find(contenttype, "x%-www%-form%-urlencoded") then
    Public.parsequery(io.read(inputsize),args)
  elseif string.find(contenttype, "multipart/form%-data") then
    Public.loadlibrary("upload")
    upl_formupload(inputsize, Private.maxfilesize, args)
  else
    error("Unsupported Media Type: "..contenttype)
  end
end

---------------------------------------------------------------------------
-- Set CGILua's "close" function
--
-- This function will be called after the user script execution
---------------------------------------------------------------------------
function Public.setclosefunction(f)
  if type(f) == "function" then
    Private.closefunction = f
  else
    error(string.format("Invalid type: expected 'function' got %s", type(f)))
  end
end

function Public.close()
  if Private.closefunction then
    Private.closefunction()
  end
end
