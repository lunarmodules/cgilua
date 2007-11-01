module(..., package.seeall)

-- Maps a URL prefix into a filepath to be used as a bootstrapper
function map(prefix, filepath)
  local p_info = cgilua.vpath or cgilua.servervariable("PATH_INFO") or ""
  local prefix = "^" .. prefix
  if p_info:find(prefix) then
     script_name = path
     cgilua.script_path = script_name
     cgilua.vpath = string.gsub(p_info, prefix, "")
  end
end