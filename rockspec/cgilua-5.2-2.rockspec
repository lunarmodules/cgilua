package = "CGILua"

version = "5.2-2"

source = {
   url = "https://github.com/lunarmodules/cgilua/archive/v5.2a2.tar.gz",
   dir = "cgilua-5.2a2",
}

description = {
   summary = "Tool for creating dynamic Web pages and manipulating data from Web forms",
   detailed = [[
      CGILua allows the separation of logic and data handling from the
      generation of pages, making it easy to develop web applications with
      Lua. CGILua can be used with a variety of Web servers and, for each
      server, with different launchers. A launcher is responsible for the
      interaction of CGILua and the Web server, for example using ISAPI on
      IIS or mod_lua on Apache. 
   ]],
   homepage = "http://lunarmodules.github.io/cgilua",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.2",
   "luafilesystem >= 1.6.0",
}

local CGILUA_LUAS = { "src/cgilua/authentication.lua", 
      "src/cgilua/cookies.lua", 
      "src/cgilua/dispatcher.lua", 
      "src/cgilua/loader.lua", 
      "src/cgilua/lp.lua", 
      "src/cgilua/mime.lua", 
      "src/cgilua/post.lua", 
      "src/cgilua/readuntil.lua", 
      "src/cgilua/serialize.lua", 
      "src/cgilua/session.lua", 
      "src/cgilua/urlcode.lua" }

build = {
   type = "builtin",
   modules = {
     cgilua = "src/cgilua/cgilua.lua"
   },
   copy_directories = { "examples", "doc", "tests" },
   install = { bin = { "src/launchers/cgilua.cgi", "src/launchers/cgilua.fcgi" } }
}

for i = 1, #CGILUA_LUAS do
    local file = CGILUA_LUAS[i]
    local mod = "cgilua." .. file:match("^src/cgilua/([^%.]+)%.lua$")
    build.modules[mod] = file
end
