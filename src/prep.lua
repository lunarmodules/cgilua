----------------------------------------------------------------------------
-- $Id: prep.lua,v 1.1 2003/04/07 15:53:53 tomas Exp $
----------------------------------------------------------------------------

local Prep = {}


-- return current line; that is, the line that starts the current mark
function Prep:CurrentLine ()
  local pos = self.marks[self.current].i
  local dummy, nl = gsub(strsub(self.s, 1, pos), "\n", "")
  return nl+1
end

-- check whether field `f' is defined in table `fields',
-- building an appropriate error message if needed
function Prep:checkField (fields, f)
  if not fields[f] then
    error(format("mark `%s' without field `%s' (at line %d)",
                  self.marks[self.current].label,
                  f,
                  self:CurrentLine()))
  end
end


-- check whether next mark is as expected,
-- building an appropriate error message if needed
function Prep:checkMark (mark)
  local next = self.marks[self.current].label
  if next == mark then
    self.current = self.current + 1
  else
    error(format("unexpected `%s' at line %d", next, self:CurrentLine()))
  end
end


-- builds a table from a string like "a='xxx', b='yyy'", and
-- returns this table.
-- Needs some additional complexity to keep all original newlines in 
-- returning field values, and to check that original string has no
-- other stuff.
function Prep:getFields (s)
  local fields = {}
  s = gsub(s, "(%s*)(%w+)[ \t]*=[ \t]*(['\"])(.-)%3(%s*),?",
        function (s1, k, _, v, s2)
          %fields[k] = s1..v..s2     -- keep eventual newlines
        end)
  s = gsub(s, '[ \t]', '')   -- remove extra spaces
  if s ~= "" then   -- still something left?
    self.current = self.marks.n   -- to call CurrentLine
    error(format("unexpected character `%s' (0x%02x) in mark %s on line %d",
          strsub(s, 1, 1), strbyte(s), self.marks[self.current].label,
          self:CurrentLine()))
  end
  return fields
end


-- Known labels
Prep.labels = { LOOP = 1, ENDLOOP = 1, ELSE = 1, IF = 1, ENDIF = 1, }

 
-- creates an array describing all marks found in string `s'. For each
-- mark, the description includes its label, its starting and ending 
-- indices (`i' and `e'), and eventual fields.
function Prep:scan ()
  local s = self.s
  local i,e = 1, 0
  local marks = {n=1; {label = "START", i = 0, e = 0}}
  self.marks = marks
  -- collect all expression marks ($| ... |$)
  while 1 do
    i, e = strfind(s, "%$|.-|%$", i)
    if not i then break end
    tinsert(marks, {label = "EXP", i = i, e = e})
    i = e+1
  end
  -- collect other marks
  i = 1
  while 1 do
    local label, fields
    i, e, label, fields = strfind(s, "<!%-%-%$%$[ \t]*(%u*)(.-)%$%$%-%->", i)
    if not i then break end
    tinsert(marks, {label = "CODE", i = i, e = e})
    if self.labels[label] then   -- known label?
      local mark = marks[marks.n]
      mark.label = label
      mark.fields = self:getFields(fields)
    end
    i = e+1
  end
  tinsert(marks, {label = "end-of-file", i = strlen(s)+1})
  -- put marks in proper order
  sort (marks, function (a,b) return a.i < b.i end)
  self.current = 2
end


function Prep:out (s)
  if s == '' then return s end
  s = gsub(s, '[ \t]+', ' ')    -- remove multiple spaces
  s = gsub(s, ' ?\n ?', '\n')   -- keeping newlines (for correct line numbers)
  -- put eventual `[[' or `]]' outside string
  s = gsub(s, "([%[%]])%1", "]],'%1%1',[[")
  return format(" cgilua.put([[%s]]); ", s)
end


function Prep:EXP ()
  local mark = self.marks[self.current]
  self.current = self.current + 1
  return format(" cgilua.put(%s or ''); ", strsub(self.s, mark.i+2, mark.e-2))
end


function Prep:CODE ()
  local mark = self.marks[self.current]
  self.current = self.current + 1
  return " do " .. strsub(self.s, mark.i+6, mark.e-5) .. " end  "
end


function Prep:LOOP ()
  local fields = self.marks[self.current].fields
  self:checkField(fields, "start")
  self:checkField(fields, "test")
  self:checkField(fields, "action")
  self.current = self.current + 1
  local body = self:body()
  self:checkMark("ENDLOOP")
  return
    format("do %s  local __ = 1; ", fields.start) ..
    format("while 1 do if __ then __ = nil else %s end; ", fields.action) ..
    format("if not (%s) then break end; ", fields.test) ..
    body ..
   "end; end; " 
end


function Prep:IF ()
  local current = self.current
  local fields = self.marks[current].fields
  self:checkField(fields, "test")
  self.current = current + 1
  local thenpart = self:body()
  local elsepart = ""
  if self.marks[self.current].label == "ELSE" then
    self.current = self.current + 1
    elsepart = " else " .. self:body()
  end
  self:checkMark("ENDIF")
  return format("if (%s) then %s  %s end", fields.test, thenpart, elsepart)
end


function Prep:body ()
  local marks = self.marks
  local code = ""
  while self.current <= marks.n do
    code = code .. self:out(strsub(self.s, marks[self.current-1].e+1,
                                            marks[self.current].i-1))
    local next = self[marks[self.current].label]
    if next then
      code = code .. next(self)
    else
      break
    end
  end
  return code
end


function Prep:Main (s)
  self.s = s
  self:scan()
  local code = self:body()
  self:checkMark("end-of-file")
  return code
end


function translate (prog, source)
  source = source or "(no source)"
  local EM = function (m)
               _ALERT(format("error translating %s:\n  %s\n", %source, m))
             end
  return call(%Prep.Main, {%Prep, prog}, "x", EM)
end
