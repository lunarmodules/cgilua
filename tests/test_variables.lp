<table>
<% for _, var in pairs { "SERVER_SOFTWARE", "SERVER_NAME", "GATEWAY_INTERFACE", "SERVER_PROTOCOL", "SERVER_PORT", "REQUEST_METHOD", "PATH_INFO", "PATH_TRANSLATED", "SCRIPT_NAME", "QUERY_STRING", "REMOTE_HOST", "REMOTE_ADDR", "AUTH_TYPE", "REMOTE_USER", "REMOTE_IDENT", "CONTENT_TYPE", "CONTENT_LENGTH", } do %>
  <tr><td><%= var %><td>=<td><%= cgilua.servervariable(var) or "<i>not defined</i>"%></tr>
<% end %>
</table>

script_vpath = [<%= cgilua.script_vpath %>]<br>
script_vdir = [<%= cgilua.script_vdir %>]<br>
urlpath = [<%= cgilua.urlpath %>]<br>
<%= cgilua.mkurlpath("outro.lua") %>
<%
vp = cgilua.script_vpath
if vp and vp ~= "" then
	cgilua.put ("PATH_INFO")
else
	cgilua.put ("SCRIPT_NAME")
end
%>
