<html>
<head><title>Embeded Lua Test</title></head>

<body>
cgi = {
<?lua
for i,v in pairs (cgi) do
	if type(v) == "table" then
		local vv = "{"
		for a,b in pairs(v) do
			vv = string.format ("%s%s = %s<br>\n", vv, a, tostring(b))
		end
		v = vv.."}"
	end
?>
<%= i %> = <%= tostring(v) %> <br>
<%
end
%>
}
<br>
Remote address: <% = cgilua.servervariable"REMOTE_ADDR"%>
<br>
ap = <?lua= tostring(ap) ?> <br>
lfcgi = <% = tostring(lfcgi) %> <br>
<%= (ap and ap.handler()) or "" %> <br>

</body>
<small>$Id: test_main.lp,v 1.4 2004/09/17 15:04:55 tomas Exp $</small>
</html>
