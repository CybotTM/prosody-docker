#!/usr/bin/lua

-- keep non-company contacts
-- keep existent company contacts
-- keep all other stuff
-- just get rid of old company contacts

dofile '/ldap.cfg.lua'
dofile '/nr_prosody_tools.lua'

local rosterPath = encode(jabberdomain) .. '/roster/'

local USERS = {}

-- getting existing company users from ldap
for i in io.popen(ldap_search_string):lines() do
    USERS[i] = 1
end
debug(table.concat(USERS, ", "))

-- serialization functions
--   val: value to write
--   fd: file handle
--   depth: indention depth - number of tabs
function serialize_to_fd(val, fd, depth)
    depth = depth or 0
    if type(val) == 'number' then
        fd:write(val)
    elseif type(val) == 'string' then
        fd:write(('%q'):format(val))
    elseif type(val) == 'boolean' then
        fd:write(val and 'true' or 'false')
    elseif type(val) == 'table' then
        local pad = string.rep('\t', depth)
        local k, v
        fd:write('{\n')
        for k, v in pairs(val) do
            fd:write(pad .. '\t[')
            serialize_to_fd(k, fd, depth + 1)
            fd:write('] = ')
            serialize_to_fd(v, fd, depth + 1)
            --fd:write((next(val, k) and ';' or '') .. '\n')
            fd:write((next(val, k) and ';' or ';') .. '\n')
        end
        fd:write(pad .. '}')
    else
        fd:write('nil')
    end
end

-- write roster to file
--   val: value to write into file
--   file: name of file to write to
function serialize_to_file(val, file)
    local fd
    if file then
        fd = io.open(file, 'w')
        assert(fd, 'Cannot open file: ' .. file)
    else
        fd = io.stdout
    end
    fd:write('return ')
    serialize_to_fd(val, fd)
    fd:write('\n')
    fd:close()
end


-- MAIN --
os.execute("mkdir -p " .. rosterPath)

for rosterFile in io.popen('ls ' .. rosterPath):lines() do
    local NEWROSTER = {}
    if string.find(rosterFile,"%.dat$") then
        debug("opening roster " .. rosterPath .. rosterFile);
        local roster = assert(loadfile(rosterPath .. rosterFile), "Failed to load roster " .. rosterPath .. rosterFile)();
        debug(rosterFile)
        for k,v in pairs(roster) do
            debug(k)
            if (k == false) then
                -- we want to keep the "false" entry in the roster file:
                NEWROSTER[k] = v
                debug("default false, keep: " .. tostring(k) .. "  " .. type(v))
            elseif string.find(tostring(k), "%" .. jabberdomain .. "$") then
                -- we want to keep existing company contacts in the roster file:
                if (USERS[k] == 1) then
                    debug("nr, keep: " .. k .. "  " .. type(v))
                    NEWROSTER[k] = v
                else
                    debug("dropping: " .. k .. " is not existing anymore")
                end
            else
                -- we want to keep all other entries in the roster file:
                NEWROSTER[k] = v
                debug("remote, keep: " .. k .. "  " .. type(v))
            end
        end
    end
    serialize_to_file(NEWROSTER, rosterPath .. rosterFile)
end
