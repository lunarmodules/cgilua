----------------------------------------------------------------------------
-- $Id: prep.lua,v 1.2 2004/09/14 11:02:58 tomas Exp $
----------------------------------------------------------------------------

local format = string.format
local gsub = string.gsub
local find = string.find
local strsub = string.sub

local concat = table.concat
local tinsert = table.insert

module (arg and arg[1])

-- function to do output
local outfunc = "io.write"

local compatmode = true


local function out (s, i, f)
  s = strsub(s, i, f or -1)
  if s == "" then return s end
  -- we could use `%q' here, but this way we have better control
  s = gsub(s, "([\\\n\'])", "\\%1")
  return format(" %s('%s'); ", outfunc, s)
end


function translate (s)
  if compatmode then
    s = gsub(s, "$|(.-)|%$", "<?lua = %1 ?>")
    s = gsub(s, "<!%-%-$$(.-)$$%-%->", "<?lua %1 ?>")
  end
  s = gsub(s, "<%%(.-)%%>", "<?lua %1 ?>")
  local res = {}
  local start = 1   -- start of untranslated part in `s'
  while true do
    local ip, fp, target, exp, code = find(s, "<%?(%w*)%s*(=?)(.-)%?>", start)
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


function setoutfunc (f)
  outfunc = f
end

function setcompatmode (c)
  compatmode = c
end
