<?lua
-- Tries to load known libraries
for _, t in ipairs { "lxp", "luasql.postgres", "luasql.mysql", "luasql.oci8", "luasql.sqlite", "luasql.odbc", "socket", "xmlrpc", "soap", "lualdap", "logging", "md5", "zip", "stable", } do
	pcall (require, t)
end

libraries = { "lxp", "luasql", "socket", "xmlrpc", "soap", "lualdap", "logging", "md5", "zip", "stable", }

local colors = { "#999999", "#CCCCCC", "#FFFFFF", }
local i = 0
function color () i = math.mod (i + 1, 3) return colors[i + 1] end

function pack_name (p) return string.gsub (p, "^([^.]+).-", "%1") end

function idx (table, field) return _G[table][field] or "" end
?>
<html>
<head><title>CGILua installation overview</title></head>

<body bgcolor="#FFFFFF">
<h1>CGILua installation overview</h1>

<table>
  <tr>
    <th>Name
    <th>Copyright
    <th>Version
    <th>Description
  </tr>
  <tr>
    <td bgcolor = "#999999">Lua
    <td bgcolor = "#999999">
    <td bgcolor = "#999999"><%= _VERSION%>
    <td bgcolor = "#999999">
  </tr>
<?lua
local pack = {}
for i, p in ipairs (libraries) do
	local s = _G[p]
	local n = pack_name(p)
	if type(_G[n]) == "table" and _G[n]._NAME then
		pack[n] = true
		table.insert (pack, n)
	end
end
table.sort (pack, function (x, y)
	local nx = _G[x] and _G[x]._NAME or ""
	local ny = _G[y] and _G[y]._NAME or ""
	return nx < ny
end)
for _, p in ipairs (pack) do bg = color() ?>
  <tr>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_NAME") %>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_COPYRIGHT") %>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_VERSION") %>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_DESCRIPTION") %>
  </tr>
<?lua end ?>
</table>

</body>
</html>
