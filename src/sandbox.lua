----------------------------------------------------------------------------
-- $Id: sandbox.lua,v 1.1 2004/04/06 17:25:38 tomas Exp $
----------------------------------------------------------------------------

local _CONTROL = {}
setmetatable(_CONTROL, {__mode = "k"})

----------------------------------------------------------------------------
-- change the environment of the given function
----------------------------------------------------------------------------
local function changefenv(f, g)
  _G.__fenv = nil
  setfenv(f, g)
  _G.__fenv = true
end

----------------------------------------------------------------------------
-- "newindex" function for the new environment
----------------------------------------------------------------------------
local function newIndex(t, key, val)
  _CONTROL[t] = _CONTROL[t] or {}
  _CONTROL[t][key] = true
  rawset(t, key, val)
end

----------------------------------------------------------------------------
-- "index" function for the new environment
----------------------------------------------------------------------------
local function createIndex(parent)
  return function(t, key)
           if _CONTROL[t] then
             if _CONTROL[t][key] then return nil end
           else
             _CONTROL[t] = {}
           end
           local perm = t.__allowed
           if type(perm) == "table" then
             perm = perm[key]
           end
           if not perm then return nil end
           local v
           if type(perm) == "function" then
             v = perm
           else
             v = parent[key]
             if v == nil then return nil end
             if type(v) == "table" then
               local nv = {}
               setmetatable(nv, {__index = createIndex(v),
                                 __newindex = newIndex})
               v = nv
               if type(perm) == "table" then
                 nv.__allowed = perm
               else
                 nv.__allowed = true
               end
             end
           end
           _CONTROL[t][key] = true
           rawset(t,key,v)
           return v
         end
end

----------------------------------------------------------------------------
-- Redefinition of 'require', allowing libraries to be stored in the
-- global environment but executed within a sandbox
----------------------------------------------------------------------------
local _STOREDLIBS = {}

local function getpath(ng)
  local path = ng.LUA_PATH
  if type(path) ~= "string" then
    path = os.getenv("LUA_PATH")
    if path == nil then
      path = "?;?.lua"
    end
  end
  return path
end

local function new_require(lib, ng)

  -- test if module was loaded in this sandbox
  local res = ng._LOADED[lib]
  if res then
    return res
  end

  -- test if the module is stored in the global environment
  local libfunction = _STOREDLIBS[lib]
  if type(libfunction) ~= "function" then
    libfunction = nil
    local path = getpath(ng)
    local comppath = string.gsub(path,"?",lib)
    for p in string.gfind(comppath, "([^;]+)") do
      local fh = io.open(p,"r")
      if fh then
        fh:close()
        local l, err = loadfile(p)
        if l then
          libfunction = l ; break
        else
          error (err)
        end
      end
    end
    if libfunction then
      _STOREDLIBS[lib] = libfunction
    else
      error("couldn't load package '"..lib.."' from path '"..path.."'")
      return
    end
  end
  
  -- run module inside sandbox if not loaded yet
  local reqname = ng._REQUIREDNAME
  ng._REQUIREDNAME = lib
  if res ~= false then
    changefenv(libfunction, ng)
  end
  res = libfunction()
  ng._REQUIREDNAME = reqname
  if res == nil then
    res = true
  end
  ng._LOADED[lib] = res
  return res
end

----------------------------------------------------------------------------
-- Creates a sandbox by establishing a new environment for the given 
-- function
----------------------------------------------------------------------------
function sandbox(f, allowed)
  if type(f) ~= "function" then
    error("bad argument #1 to sandbox ('function' expected got '"..
           type(f).."')")
  end
  if type(allowed) ~= "table" and allowed ~= true then
    error("bad argument #2 to sandbox ('table' or true expected got '"..
           type(allowed).."')")
  end
  local ng = {}
  _G.__fenv = true
  setmetatable(ng, {__index = createIndex(_G),
                    __newindex = newIndex})
  changefenv(f, ng)

  ng._G = ng
  ng.__allowed = allowed
  ng._LOADED = {}

  -- redefines loadfile and loadstring so that the returned functions
  -- execute in the new environment
  ng.loadfile = function(p)
                  local f,e = loadfile(p)
                  if f then
                    changefenv(f, ng)
                  end
                  return f,e
                end
  ng.loadstring = function(s)
                  local f,e = loadstring(s)
                  if f then
                    changefenv(f, ng)
                  end
                  return f,e
                end
  ng.require = function(s)
                return new_require(s, ng)
               end

  return f
end
