-- This file should be executed before any script in this directory
-- according to the configuration (cgilua/conf.lua).

cgilua.addclosefunction (function ()
	cgilua.put [[
<p>
<small>
<a href="test_main.html">Main</a>]]
	for _, test in {
			{ "Get", "test_main.lua", {ab = "cd", ef = "gh"} },
			{ "Cookies", "test_cookies.lua", },
			{ "FileSystem", "test_fs.lua", },
			{ "Libraries", "test_lib.lua", },
			{ "Session", "test_session.lua", },
			{ "Variables", "test_variables.lp", },
		} do
		cgilua.put (string.format (' &middot; <a href="%s">%s</a>',
			cgilua.mkurlpath (test[2], test[3]), test[1]))
	end
	cgilua.put [[
</small>]]
end)
