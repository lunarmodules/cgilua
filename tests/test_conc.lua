cgilua.htmlheader()
for i = 1,1000 do
	cgilua.put (i)
	for ii = 1,1000 do
		cgilua.put ("<!>")
	end
	cgilua.put ("\n")
end
cgilua.put ("End")
