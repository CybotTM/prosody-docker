#! /usr/bin/lua
-- 20101229 initial shape with license and all
-- 20110105 next version, functionized and nicer names
-- 20110111 writing directly to file instead of creating long string
-- 20110113 added persistent room configuration handling
-- 20110113 changed license to AGPL
-- 20110804 member-only and all company users as members
--
-- ldap2prosody: getting data from Active Directory and write to
-- prosody config files, for auto groupchat bookmarks and automatic
-- buddielists (shared roster)
-- the script assumes you are using Active Directory and have (certain)
-- groups of users there who should a) be automatically included into
-- the shared roster of other members in that group, as well as b) an
-- automatic bookmark and popup into that groups' conference room.
-- (so far supported by the xmpp client of choice, pidgin doesn't yet)
--
-- (c) kloschi@subsignal.org 29.12.2010
--
--  ldap2prosody is free software: you can redistribute it and/or modify
--  it under the terms of the GNU Affero General Public License, version 3,
--  as published by the Free Software Foundation.
--
--  ldap2prosody is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Affero General Public License for more details.
--
--  You should have received a copy of the GNU Affero General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'lualdap'

dofile '/ldap.cfg.lua'
dofile '/nr_prosody_tools.lua'

-- init ldap
local ld = assert (lualdap.open_simple ( adhost, aduser, adpass))

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
            fd:write((next(val, k) and ';' or '') .. '\n')
        end
        fd:write(pad .. '}')
    else
        fd:write('nil')
    end
end

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

function tableMerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == 'table' then
            if type(t1[k] or false) == 'table' then
                tableMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end end
    return t1
end

function makebase (group)
    local count = 1
    local mybase = {}
    while group[count] do
        mybase[count] = 'CN=' .. group[count] .. base_suffix
        count = count + 1
    end
    return mybase
end

function make_persistent(roomname, roomfull, _affiliations_members)

    -- write persistent.dat
    os.execute("mkdir -p " .. libpath .. encode(confserver))
    local myfile = libpath .. encode(confserver) .. '/' .. persfile
    local datafile
    local success
    success, datafile = pcall(dofile, myfile);
    if success then
        if not (type(datafile) == "table") then
            datafile = {}
        end
        datafile[string.lower(roomfull)] = 'true'
        serialize_to_file(datafile, myfile)
    end

    -- write config/roomname.dat
    os.execute("mkdir -p " .. libpath .. encode(confserver) .. '/config')
    myfile = libpath .. encode(confserver) .. '/config/' .. string.lower(roomname) .. '.dat'
    success, datafile = pcall(dofile, myfile);
    local newdata = {
        ['jid'] = roomname;
        ['_data'] = {
            ['description'] = room_prefix .. roomname;
            ['members_only'] = true;
            ['changesubject'] = true;
            ["whois"] = "anyone";
            ['persistent'] = true;
        };
        ['_affiliations'] = _affiliations;
    };

    newdata._affiliations = tableMerge(_affiliations_members, newdata._affiliations)
    --serialize_to_file(newdata._affiliations)

    if success and merge == true then
        newdata = tableMerge(datafile, newdata)
    end
    serialize_to_file(newdata, myfile)
end


function getusers(base, group, outfile, is_chat)
    local fd = io.open(outfile, 'w')
    assert(fd, 'Cannot open file: ' .. outfile)
    local count = 1
    while base[count] do
        local roomname = string.gsub(chatgroup[count], '^.*%-', '')
        local roomfull = roomname .. '@' .. confserver
        local _affiliations_members =  {}
        -- write groupheader for prosody (appended to a string)
        if is_chat then
            fd:write('[' .. roomfull .. ']\n')
        else
            fd:write('[' .. rostergroup[count] .. ']\n')
        end
        for dn, attribs in ld:search { base = base[count], scope = 'subtree', attrs = 'member'} do
            if attribs then
                -- here attribs holds the members of the group we looked for
                for _,v in pairs (attribs['member']) do
                    for dn2, userattribs in ld:search { base = tostring(v), scope = 'subtree' } do
                        if userattribs then
                            -- iterating through groupmembers we want following values
                            local user = userattribs['sAMAccountName'] .. '@' .. jabberdomain
                            local displayname = userattribs['displayName']
                            _affiliations_members[user] = 'member'
                            fd:write(user .. '=' .. displayname .. '\n')

                            debug("User: " .. user .. " |\t" .. displayname)

                        end end end end end
        fd:write('\n')
        -- groupchats get added to the persistent file and configured with default affiliations and such
        if is_chat then
            make_persistent(roomname, roomfull, _affiliations_members)
        end
        count = count + 1
    end
    fd:close()
end

local mybase = makebase(chatgroup)
getusers (mybase, chatgroup, chatfile, true)

local mybase = makebase(rostergroup)
getusers (mybase, rostergroup, rosterfile)

