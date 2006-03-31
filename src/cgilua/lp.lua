----------------------------------------------------------------------------
-- HTML Preprocessor.
--
-- $Id: lp.lua,v 1.6 2006/03/31 06:17:45 tuler Exp $
----------------------------------------------------------------------------

local assert, error, loadstring = assert, error, loadstring
local find, format, gsub, strsub = string.find, string.format, string.gsub, string.sub
local concat, tinsert = table.concat, table.insert
local open = io.open
local getfenv, setfenv = getfenv, setfenv

module (arg and arg[1])

----------------------------------------------------------------------------
-- function to do output
local outfunc = "io.write"
-- accepts the old expression field: `$| <Lua expression> |$'
local compatmode = true

----------------------------------------------------------------------------
local function out (s, i, f)
	s = strsub(s, i, f or -1)
	if s == "" then return s end
	-- we could use `%q' here, but this way we have better control
	s = gsub(s, "([\\\n\'])", "\\%1")
	return format(" %s('%s'); ", outfunc, s)
end


----------------------------------------------------------------------------
function translate (s)
	if compatmode then
		s = gsub(s, "$|(.-)|%$", "<?lua = %1 ?>")
		s = gsub(s, "<!%-%-$$(.-)$$%-%->", "<?lua %1 ?>")
	end
	s = gsub(s, "<%%(.-)%%>", "<?lua %1 ?>")
	local res = {}
	local start = 1   -- start of untranslated part in `s'
	while true do
		local ip, fp, target, exp, code = find(s, "<%?(%w*)[ \t]*(=?)(.-)%?>", start)
		if not ip then break end
		tinsert(res, out(s, start, ip-1))
		if target ~= "" and target ~= "lua" then
			-- not for Lua; pass whole instruction to the output
			tinsert(res, out(s, ip, fp))
		else
			if exp == "=" then   -- expression?
				tinsert(res, format(" %s(%s);", outfunc, code))
			else  -- command
				tinsert(res, format(" %s ", code))
			end
		end
		start = fp + 1
	end
	tinsert(res, out(s, start))
	return concat(res)
end


----------------------------------------------------------------------------
function setoutfunc (f)
	outfunc = f
end

----------------------------------------------------------------------------
function setcompatmode (c)
	compatmode = c
end

----------------------------------------------------------------------------
local cache = {}

----------------------------------------------------------------------------
function compile (string, chunkname)
	local f, err = cache[string]
	if f then return f end
	local prog = translate (string)
	f, err = loadstring (translate (string), chunkname)
	if not f then error (err, 3) end
	cache[string] = f
	return f
end

----------------------------------------------------------------------------
function include (filename, env)
	-- read the whole contents of the file
	local fh = assert (open (filename))
	local src = fh:read("*a")
	fh:close()
	-- translates the file into a function
	local prog = compile (src, '@'..filename)
	local _env
	if env then
		_env = getfenv (prog)
		setfenv (prog, env)
	end
	prog ()
end
