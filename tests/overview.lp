<?lua
-- Tries to load known libraries
for _, t in ipairs { "lxp", "luasql.postgres", "luasql.mysql", "luasql.oci8", "luasql.sqlite", "luasql.odbc", "socket", "xmlrpc", "soap", "lualdap", } do
	pcall (require, t)
end

local colors = { "#999999", "#CCCCCC", "#FFFFFF", }
local i = 0
function color () i = math.mod (i + 1, 3) return colors[i + 1] end

function pack_name (p) return string.gsub (p, "^([^.]+).-", "%1") end

function idx (table, field) return _G[table][field] end
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
for p, s in pairs (package.loaded) do
	local n = pack_name(p)
	if _G[n] then
		pack[n] = true
	end
end
for p in pairs (pack) do bg = color() ?>
  <tr>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_NAME") %>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_COPYRIGHT") %>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_VERSION") %>
    <td bgcolor = "<%= bg %>"><%= idx(p,"_DESCRIPTION") %>
  </tr>
<?lua end ?>
</body>
</html>
