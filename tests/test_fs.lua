cgilua.htmlheader ()
cgilua.put ("<h1>Testing Filesystem library</h1>\n")
cgilua.put ("<table>\n")
cgilua.put ("<tr><td colspan=2>Testing <b>dir</b></td></tr>\n")
local i = 0
for file in luafilesystem.dir ("/usr/local/cgilua") do
	i = i+1
	cgilua.put ("<tr><td>"..i.."</td><td>"..file.."</td></tr>\n")
end
cgilua.put ("</table>\n")
