----------------------------------------------------------------------------
-- $Id: upload.lua,v 1.1 2003/04/07 15:53:55 tomas Exp $ 
--
-- Multipart/form-data processing (with file upload)
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- Multipart/form-data (RFC 2388) contains a series of parts, each part
-- corresponding to a form 'field'. Every part is composed by lines
-- containing the field headers, followed by the field contents.  An "empty" 
-- line separates the headers from the field contents. CRLF is used as a 
-- line separator.
--
-- A "boundary" string not occurring in any of the form-data is defined in 
-- the CONTENT_TYPE metavariable. This boundary string prefixed with "--" 
-- (and alone in a line) indicates the beginning of a new part. The boundary 
-- string prefixed and suffixed with "--" (and alone in a line) indicates 
-- the end of input.
-- 
-- Each part in a multipart/form-data input contains at least a 
-- content-disposition header, where a 'name' attribute specifies the 
-- corresponding field name. The presence of a 'filename' attribute in this 
-- header indicates a file upload (although not required in file uploads,
-- this attribute is included by commonly used browsers like Netscape and 
-- Internet Explorer).
-- A part can also contain optional headers, such as 'content-type' and 
-- 'content-transfer-enconding'.
----------------------------------------------------------------------------

local Upload = {
   -- environment for processing multipart/form-data input
   boundary = nil,    -- boundary string that separates each 'part' of input
   maxfilesize = nil, -- maximum size for file upload
   inputfile = nil,   -- temporary file for inputting form-data
   bytesleft = nil    -- number of bytes yet to be read
}

----------------------------------------------------------------------------
-- Extract the boundary string from CONTENT_TYPE metavariable
----------------------------------------------------------------------------
function Upload:getboundary ()
  local _,_,boundary = strfind(getenv("CONTENT_TYPE"), "boundary%=(.-)$")
  return  "--"..boundary 
end

----------------------------------------------------------------------------
-- Create a table containing the headers of a multipart/form-data field
----------------------------------------------------------------------------
function Upload:breakheaders (hdrdata)
  local headers = {}
  gsub(hdrdata, '([^%c%s:]+):%s+([^\n]+)', function(type,val)
    type = strlower(type)
    %headers[type] = val
  end)
  return headers
end

----------------------------------------------------------------------------
-- Read the headers of the next multipart/form-data field 
--
--  This function returns a table containing the headers values. Each header
--  value is indexed by the corresponding header "type". 
--  If end of input is reached (no more fields to process) it returns nil.
----------------------------------------------------------------------------
function Upload:readfieldheaders ()
  --
  -- read stdin until an "empty" line is found (end of field headers)
  --
  local EOH = "\r\n\r\n" -- <CR><LF><CR><LF>
  local bytesread, status = copybounded(self.inputfile, EOH, self.bytesleft)
  self.bytesleft = self.bytesleft - bytesread 

  if status ~= "boundary" then
    return nil, 0		-- no empty line found: end of input 
  end				--  (no more fields to process)

  -- read header data from temporary file
  local hdrdata = read(self.inputfile, bytesread - strlen(EOH))

  -- parse headers
  return self:breakheaders(hdrdata)
end

----------------------------------------------------------------------------
-- Extract a field name (and possible filename) from its disposition header
----------------------------------------------------------------------------
function Upload:getfieldnames (headers)
  local disposition_hdr = headers["content-disposition"]
  local attrs = {}
  if disposition_hdr then
    gsub(disposition_hdr, ';%s*([^%s=]+)="(.-)"', function(attr, val)
	   %attrs[attr] = val
         end)
  else
    error("Error processing multipart/form-data."..
          "\nMissing content-disposition header")
  end
  return attrs.name, attrs.filename
end

----------------------------------------------------------------------------
-- Read the contents of a 'regular' field to a string
----------------------------------------------------------------------------
function Upload:readfieldcontents ()

  -- read stdin until the boundary string is found after a line separator

  local boundaryline = "\r\n"..self.boundary
  local bytesread, status = copybounded(self.inputfile, boundaryline, 
                                        self.bytesleft)
  self.bytesleft = self.bytesleft - bytesread

  if status ~= "boundary" then
     error("Error processing multipart/form-data.\nUnexpected end of input")
  end

  -- copy the field contents to a string
  return read(self.inputfile, bytesread - strlen(boundaryline))
end

----------------------------------------------------------------------------
-- Read the contents of a 'file' field to a temporary file (file upload)
----------------------------------------------------------------------------
function Upload:fileupload (filename)

  -- maximum upload size 
  local count = min(self.bytesleft, self.maxfilesize)
 
  -- create a temporary file for uploading the file field
  local file, err = tmpfile()
  if file == nil then
    cgilua.discardinput(self.bytesleft)
    error("Cannot create a temporary file.\n"..err)
  end      

  -- copy stdin to the temporary file until the boundary string is found 
  -- after a line separator

  local boundaryline = "\r\n"..self.boundary
  local bytesread, status = copybounded(file, boundaryline, count)
  self.bytesleft = self.bytesleft - bytesread

  if status == "boundary" then
    return file, bytesread - strlen(boundaryline)
  elseif status == "count" and count == self.maxfilesize then
    cgilua.discardinput(self.bytesleft)
    error(format("Maximum file size (%d KB) exceeded while uploading '%s'", 
                 self.maxfilesize / 1024, filename))
  else
     error("Error processing multipart/form-data."..
           format("\nUnexpected end of input while uploading %s", filename))
  end
end

----------------------------------------------------------------------------
-- Compose a file field 'value' 
----------------------------------------------------------------------------
function Upload:filevalue (filehandle, filename, filesize, headers)
  -- the temporary file handle
  local value = { file = filehandle,
                  filename = filename,
                  filesize = filesize }
  -- copy additional header values
  for hdr, hdrval in headers do
    if hdr ~= "content-disposition" then
      value[hdr] = hdrval
    end
  end
  return value
end

----------------------------------------------------------------------------
-- Process multipart/form-data 
--
-- This function receives the total size of the incoming multipart/form-data, 
-- the maximum size for a file upload, and a reference to a table where the 
-- form fields should be stored.
--
-- For every field in the incoming form-data a (name=value) pair is 
-- inserted into the given table. [[name]] is the field name extracted
-- from the content-disposition header.
--
-- If a field is of type 'file' (i.e., a 'filename' attribute was found
-- in its content-disposition header) a temporary file is created 
-- and the field contents are written to it. In this case,
-- [[value]] has a table that contains the temporary file handle 
-- (key 'file') and the file name (key 'filename'). Optional headers
-- included in the field description are also inserted into this table,
-- as (header_type=value) pairs.
--
-- If the field is not of type 'file', [[value]] contains the field 
-- contents.
----------------------------------------------------------------------------
function Upload:Main (inputsize, maxfilesize, args)

  -- create a temporary file for processing input data
  local inputf,err = tmpfile()
  if inputf == nil then
    cgilua.discardinput(inputsize)
    error("Cannot create a temporary file.\n"..err)
  end

  -- set the environment for processing the multipart/form-data
  self.inputfile = inputf
  self.bytesleft = inputsize
  self.maxfilesize = maxfilesize or inputsize 
  self.boundary = self:getboundary()

  while (self.bytesleft > 0) do

    -- read the next field header(s)
    local headers = self:readfieldheaders()
    if not headers then break end	-- end of input

    -- get the name attributes for the form field (name and filename)
    local name, filename = self:getfieldnames(headers)

    -- get the field contents
    local value
    if filename then
      local filehandle, filesize = self:fileupload(filename)
      value = self:filevalue(filehandle, filename, filesize, headers)
    else
      value = self:readfieldcontents()
    end

    -- insert the form field into table [[args]]
    cgilua.insertfield(args, name, value)
  end
end

function upl_formupload (inputsize, maxfilesize, args)
  %Upload.Main(%Upload, inputsize, maxfilesize, args)
end
