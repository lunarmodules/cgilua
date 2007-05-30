module(..., package.seeall)

-- inferred_name refers to the name of the launcher without the extension
-- It can be used to set cgilua.script_path to a bootstrap file named
-- after the launcher name utilized in the URL
_, inferred_name = cgilua.splitpath(cgilua.servervariable("SCRIPT_NAME"))
inferred_name = string.gsub(inferred_name, "%.[^%.]-$","")

-- Maps a URL prefix into a filepath to be used as a bootstrapper
function map(prefix, filepath)
  local p_info = cgilua.servervariable("PATH_INFO") or ""
  local prefix = "^" .. prefix
  if p_info:find(prefix) then
     script_name = path
     cgilua.script_path = script_name
     path_info = string.gsub(p_info, prefix, "")
  end
end