
table.insert(disco_items, { "proxy65.xmpp.example.org", "ACME Proxy65"})

proxy65_interface = "0.0.0.0"
proxy65_ports = { 5000 }

Component "proxy65.xmpp.example.org" "proxy65"
    --proxy65_address = "proxy.example.org" -- advertised address of the proxy. if unset hostname of the component is used
    proxy65_acl = { "example.org" }
    -- proxy65_acl = { "theadmin@anotherdomain.com", "only@fromwork.de/AtWork" } -- when specified all users will be denied access unless in the list.
