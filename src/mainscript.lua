----------------------------------------------------------------------------
-- $Id: mainscript.lua,v 1.1 2003/04/07 15:53:52 tomas Exp $
--
-- CGILua "main" script
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- Load auxiliar functions defined in CGILua namespace (cgilua)
----------------------------------------------------------------------------
local aux = CL_map.main_dir.."auxiliar.lua"
assert(dofile(aux), "Error loading '"..aux.."'")

----------------------------------------------------------------------------
-- CGILua Libraries configuration
----------------------------------------------------------------------------

--
-- Set CGILua's default libraries directory
--
cgilua.setlibdir(CL_map.main_dir)

--
-- Authorized libraries
--
--  The following table describes the authorized libraries in the CGILua 
--  environment.
--  Each entry in this table provides the information used by the auxiliar 
--  function 'CL_loadlibrary' for loading and initializing the corresponding 
--  library. 
--   
--  An authorized library can be implemented as a dynamic library (described 
--  by field "dyn"), as a lua file (described by field "lua"), or both.
--
--  The description of a dynamic library (field "dyn") *must* contain the 
--  following information:
--
--     libname: the 'basename' of the file that stores the library. 
--              On Unix systems the prefix 'lib' and the suffix '.so' will 
--              be automatically added to this basename. On Windows systems, 
--              the suffix '.dll' will be automatically added.
--     init:    the name of the function that initializes (opens) the 
--              library.
--              This function will be called when the corresponding library 
--              is loaded.
--
--  The description of lua file *must* contain the file name (libname).
--
--  Both dynamic libraries and lua files are loaded, by default, from 
--  CGILua's 'libraries directory'. However, if a  "libdir" field is present 
--  in a library description, its contents override CGILua's default libraries
--  directory for the corresponding library.
--
local authorizedLibs = {
          preprocess = {
            lua = { libname = "prep.lua" } },
          upload = {
            lua = { libname = "upload.lua" } },
          auxiliar = {
            loaded = "yes" },			-- library is already loaded
          cookies = { 
            lua = { libname = "cookies.lua" } },
          htk = { lua = { libname = "htk.lua" } },
          libconcat = {
            dyn = { libname = "concat",
                    libdir = nil,
                    init = "lua_concatlibopen" } },
          poslib = {
            dyn = { libname = "poslib",
                    libdir = nil,
                    init = "lua_poslibopen" } },
          md5 = {
            dyn = { libname = "md5",
                    libdir = nil,
                    init = "md5lib_open" } },
          luasql = {
            dyn = { libname = "luasql",
                    libdir = nil,
                    init = "lua_sqllibopen" } },
          luasocket = {
            dyn = { libname = "luasocket",
                    libdir = nil,
                    init = "lua_socketlibopen" } },
          ftp = { lua = { libname = "ftp.lua" } },
          http = { lua = { libname = "http.lua" } },
          smtp = { lua = { libname = "smtp.lua" } },
          concat = { lua = { libname = "concat.lua" } },
          url = { lua = { libname = "url.lua" } },
          code = { lua = { libname = "code.lua" } },
}
cgilua.setauthlibs(authorizedLibs)

----------------------------------------------------------------------------
-- CGILua "security" configuration
---------------------------------------------------------------------------
--
-- copy 'map' information to CGILua namespace
--
cgilua.script_path = CL_map.script_path

--
-- remove globals not to be accessed by CGILua scripts
-- 
cgilua.removeglobals{

  -- functions to be removed from the environment
  "loadlib","unloadlib","callfromlib", "execute",

  -- other data to be removed
  "CL_map",
}

--
-- Maximum "total" input size allowed (in bytes)
--
-- (total size of the incoming request data as defined by 
--    the metavariable CONTENT_LENGTH)
cgilua.setmaxinput(1024 * 1024) -- 1 MB

--
-- Maximum size for file upload (in bytes)
--   (can be redefined by 'env.lua' or a script,
--    but 'maxinput' is always checked first)
--
cgilua.setmaxfilesize(500 * 1024) -- 500 KB

----------------------------------------------------------------------------
-- Configure CGILua environment and execute the script
----------------------------------------------------------------------------

-- get the 'physical' directory of the script
cgilua.script_pdir = cgilua.splitpath(cgilua.script_path)

-- check if CGILua handles this script type
local type = cgilua.getscripttype(cgilua.script_path)
if type ~= "lua" and type ~= "html" then
  cgilua.redirect(cgilua.mkabsoluteurl(getenv("PATH_INFO")))
else
  -- get the 'virtual' path of the script (PATH_INFO)
  cgilua.script_vpath = getenv("PATH_INFO")

  -- get the 'virtual' directory of the script
  --  (used to create URLs to scripts in the same 'virtual' directory)
  cgilua.script_vdir = cgilua.splitpath(getenv("PATH_INFO"))

  -- save the URL path to cgilua
  cgilua.urlpath = getenv("SCRIPT_NAME")

  -- change current directory to the script's "physical" dir
  chdir(cgilua.script_pdir)

  -- set the script environment
  cgilua.doenv(cgilua.script_pdir.."env.lua")

  -- parse the incoming request data
  cgi = {}
  if getenv("REQUEST_METHOD") == "POST" then
    cgilua.parsepostdata(cgi)
  end
  cgilua.parsequery(getenv("QUERY_STRING"),cgi)

  --
  -- execute/preprocess the script
  --
  if type == "lua" then
    cgilua.doscript(cgilua.script_path)
  elseif type == "html" then
    cgilua.contentheader("text","html")
    cgilua.includehtml(cgilua.script_path)
  end
  cgilua.close()				-- "close" function
end

