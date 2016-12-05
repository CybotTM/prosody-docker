-- groups from PDC/AD to taken care of for shared roster and groupchats
rostergroup = {
    'Employees'
}

chatgroup = {
    'R+D',
    'HR',
    'Marketing',
    'Sales',
    'Development'
}

-- LDAP search base - appended to chatgroups when searching LDAP
base_suffix = ',OU=ACME,DC=example,DC=org'
group_suffix = ',OU=Groups' .. base_suffix
user_suffix = ',OU=Users' .. base_suffix

room_prefix = 'ACME '

-- default affiliations of the conference rooms
_affiliations = {
    ['admin@example.org'] = 'owner';
    ['other@example.org'] = 'member';
    ['example.org'] = 'member';
}

-- Active Driectory Server and Credentials
adhost = 'ldap.example.org'
aduser = 'readuser'
adpass = 'readuser'

-- Domainname of Jabberserver and Conferenceserver
jabberdomain = 'example.org'
confserver = 'conference.xmpp.example.org'

-- Prosody config files
rosterfile = '/etc/prosody/groups.cfg.txt'
chatfile = '/etc/prosody/groupchats.cfg.txt'
--rosterfile = 'groups.cfg.txt'
--chatfile = 'groupchats.cfg.txt'

libpath = '/var/lib/prosody/'
--libpath = './' .. confserver .. '/'

persfile = 'persistent.dat'

-- set merge to true when there is hadnwritte roomconfig to merge with the
-- defaults writte from this script
--merge = true
merge = false

ldap_search_string = "ldapsearch -h " .. adhost .. " -D " .. aduser .. " -w " .. adpass .. " -b " .. user_suffix .. " -LLL | grep Principal | awk {'print $2'}"
