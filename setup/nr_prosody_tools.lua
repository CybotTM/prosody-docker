#!/usr/bin/lua


-- use same path econding/decoing function like prosody:
-- https://github.com/bjc/prosody/blob/master/util/datamanager.lua
---- utils -----
local format = string.format;
local urlcodes = setmetatable({}, { __index = function (t, k) t[k] = char(tonumber(k, 16)); return t[k]; end });

decode = function (s)
    return s and (s:gsub("%%(%x%x)", urlcodes));
end

encode = function (s)
    return s and (s:gsub("%W", function (c) return format("%%%02x", c:byte()); end));
end


-- Give warning with, optionally, the name of program and file
--   s: warning string
function warn(s)
    if prog.name then write(_STDERR, prog.name .. ": ") end
    if file then write(_STDERR, file .. ": ") end
    writeLine(_STDERR, s)
end

-- Die with error
--   s: error string
function die(s)
    warn(s)
    error()
end

-- Die with line number
--   s: error string
function dieLine(s)
    die(s .. " at line " .. line)
end

-- Die with error if value is nil
--   v: value
--   s: error string
function affirm(v, s)
    if not v then die(s) end
end

-- Die with error and line number if value is nil
--   v: value
--   s: error string
function affirmLine(v, s)
    if not v then dieLine(s) end
end

-- Print a debugging message
--   s: debugging message
function debug(s)
    if _DEBUG then writeLine(_STDERR, s) end
end
