-- $Id: test_main.lua,v 1.8 2004/11/22 17:33:45 tomas Exp $
if ap then handler = ap.handler() end
cgilua.htmlheader()
cgilua.put[[
<html>
<head><title>Script Lua Test</title></head>

<body>
cgi = {
]]

for i,v in pairs (cgi) do
	if type(v) == "table" then
		local vv = "{"
		for a,b in pairs(v) do
			vv = string.format ("%s%s = %s<br>\n", vv, a, tostring(b))
		end
		v = vv.."}"
	end
	cgilua.put (string.format ("%s = %s<br>\n", i, tostring(v)))
end
cgilua.put "}<br>\n"
cgilua.put ("Remote address: "..cgilua.servervariable"REMOTE_ADDR")
cgilua.put "<br>\n"
cgilua.put ("ap="..tostring(ap).."<br>\n")
cgilua.put ("lfcgi="..tostring(lfcgi).."<br>\n")
if handler then cgilua.put (tostring(handler).."<br>\n") end

-- Checking Virtual Environment
local my_output = cgilua.put
cgilua.put = nil
local status, err = pcall (function ()
	assert (cgilua.put == nil, "cannot change cgilua.put value")
end)
cgilua.put = my_output
assert (status == true, err)

-- Checking require
local status, err = pcall (function () require"unknown_module" end)
--cgilua.put(tostring(status)..": "..tostring(err).."<br>\n")
assert (status == false, "<tt>unknown_module</tt> loaded!")
local status, err = pcall (function () package.path="." require"test_main" end)
--cgilua.put(tostring(err).."<br>\n")
assert (status == false, "<i>package.path</i> was changed!")
local status, err = pcall (function () package.path="." require"cgilua.cookies" end)
assert (status == true, "<i>package.path</i> was changed!")

cgilua.put[[
<p>
</body>
<small>$Id: test_main.lua,v 1.8 2004/11/22 17:33:45 tomas Exp $</small>
</html>
]]
