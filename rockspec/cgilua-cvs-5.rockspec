package = "CGILua"

version = "cvs-5"

description = {
   summary = "Tool for creating dynamic Web pages and manipulating data from Web forms",
   detailed = [[
      CGILua allows the separation of logic and data handling from the
      generation of pages, making it easy to develop web applications with
      Lua. CGILua can be used with a variety of Web servers and, for each
      server, with different launchers. A launcher is responsible for the
      interaction of CGILua and the Web server, for example using ISAPI on
      IIS or mod_lua on Apache. 
   ]]
}

dependencies = {
   "lua >= 5.1",
   "luafilesystem >= 1.5.0",
}

source = {
   url = "git://github.com/lunarmodules/cgilua.git",
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
   type = "module",
   modules = {
     cgilua = "src/cgilua/cgilua.lua"
   },
   install = { bin = { "src/launchers/cgilua.cgi", "src/launchers/cgilua.fcgi" } },
   copy_directories = { "examples", "docs" }
}

for i = 1, #CGILUA_LUAS do
    local file = CGILUA_LUAS[i]
    local mod = "cgilua." .. file:match("^src/cgilua/([^%.]+)%.lua$")
    build.modules[mod] = file
end
