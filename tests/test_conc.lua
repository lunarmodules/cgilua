cgilua.htmlheader()
local pid, ppid = ap.pid ()
cgilua.put ("pid = "..pid.." ("..ppid..")".."<br>\n")

assert(type(stable.get) == "function")
assert(type(stable.set) == "function")

local a = stable.get"a" or 0
cgilua.put ("count = "..a.."<br>\n")
stable.set ("a", a + 1)

local f = stable.get"f"
cgilua.put ("f = "..tostring (f).."&nbsp;&nbsp;")
if not f then
	local d = os.date()
	stable.set ("f", function () return d end)
else
	cgilua.put ("f() = "..tostring (f ()).."<br>\n")
end

cgilua.put"<br>\n"
for i = 1,1000 do
	cgilua.put (i)
	for ii = 1,1000 do
		cgilua.put ("")
	end
	cgilua.put ("\n")
end
cgilua.put ("End")
