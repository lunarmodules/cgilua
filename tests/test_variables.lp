<table>
<% for _, var in pairs { "SERVER_SOFTWARE", "SERVER_NAME", "GATEWAY_INTERFACE", "SERVER_PROTOCOL", "SERVER_PORT", "REQUEST_METHOD", "PATH_INFO", "PATH_TRANSLATED", "SCRIPT_NAME", "QUERY_STRING", "REMOTE_HOST", "REMOTE_ADDR", "AUTH_TYPE", "REMOTE_USER", "REMOTE_IDENT", "CONTENT_TYPE", "CONTENT_LENGTH", } do %>
  <tr><td><%= var %><td>=<td><%= cgilua.servervariable(var) or "<i>not defined</i>"%></tr>
<% end %>
</table>

<% if ap then %>
  <p>
  <table>
  <% for i, v in pairs {ap.get_header()} do %>
    <tr><td><%= i %><td>&nbsp;<td><%= v %></tr>
  <% end %>
  </table>
<% end %>

<p>
