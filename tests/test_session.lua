function pt (tab)
	for i, v in pairs (tab) do
		local vv = v
		if type(v) == "table" then
			vv = ""
			for _i, _v in pairs (v) do
				vv = vv..string.format ("%s = %q, ", _i, _v)
			end
			vv = '{'..vv..'}'
		end
		cgilua.put (string.format ("%s = %s<br>\n", tostring (i), tostring (vv)))
	end
end


if cgi.field then
	if not cgilua.session.field then
		cgilua.session.field = {}
	end
	table.insert (cgilua.session.field, cgi.field)
end
cgilua.htmlheader()
cgilua.put "cgi = {<br>\n"
pt (cgi)
cgilua.put "}<br>\n"
cgilua.put "session = {<br>\n"
pt (cgilua.session)
cgilua.put "}<br>\n"

cgilua.put [[
<form action="]]
cgilua.put (cgilua.mkurlpath"test_session.lua")
cgilua.put [[" method="POST">
  field: <input type="text" name="field" value="]]
cgilua.put (cgi.field or "")
cgilua.put [["><br>
  <input type="submit"><br>
</form>]]