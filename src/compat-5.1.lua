_G._PATH = _PATH or os.getenv("LUA_PATH") or "/usr/local/share/lua/5.0"
_G._CPATH = _CPATH or os.getenv("LUA_CPATH") or "/usr/local/lib/lua/5.0"


local function search (path, name)
  for c in string.gfind(path, "[^;]+") do
    c = string.gsub(c, "%?", name)
    local f = io.open(c)
    if f then   -- file exist?
      f:close()
      return c
    end
  end
  return nil    -- file not found
end


function _G.require (name)
  if not _LOADED[name] then
    _LOADED[name] = true
    local filename = string.gsub(name, "%.", "/")
    local fullname = search(_PATH, filename)
    if fullname then
      local f = assert(loadfile(fullname))
      local old_arg = arg
      arg = { name }
      local res = f(name)
      arg = old_arg
      if res then _LOADED[name] = res end
    else
      -- should try C libraries?
      fullname = search(_CPATH, filename)
      if fullname then
        local lastname = string.gsub(filename, "^.*%/([^/]+)$", "%1")
        local f = assert(loadlib(fullname, "luaopen_"..lastname))
        local res = f(name)
        if res then _LOADED[name] = res end
      else
        error("cannot find "..name.." in path ".._PATH.." nor in path ".._CPATH, 2)
      end
    end
  end
  return _LOADED[name]
end


local function getfield (t, f)
  for w in string.gfind(f, "[%w_]+") do
    if not t then return nil end
    t = t[w]
  end
  return t
end


local function setfield (t, f, v)
  for w in string.gfind(f, "([%w_]+)%.") do
    t[w] = t[w] or {}   -- create table if absent
    t = t[w]            -- get the table
  end
  local w = string.gsub(f, "[%w_]+%.", "")   -- get last field name
  t[w] = v            -- do the assignment
end


function _G.package (name, aname)
  local _G = getfenv(0)       -- simulate C function environment
  name = aname or name
  local ns = getfield(_G, name)         -- search for namespace
  if not ns then
    ns = {}                   -- create new namespace
    setmetatable(ns, {__index = _G})
    setfield(_G, name, ns)
  end
  _G._LOADED[name] = ns
  setfenv(2, ns)
end
