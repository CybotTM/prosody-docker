
table.insert(disco_items, { "conference.xmpp.example.org", "ACME MUC" })

Component "conference.xmpp.example.org" "muc"
    modules_enabled = {
        "muc_log";
        "muc_log_http";
    }
    muc_log_by_default = true -- Log all rooms by default

    muc_log_http = {
        show_join = false; -- default is true
        show_status = false; -- default is true
        show_presences = false;
        -- theme = "prosody"; -- default is theme "prosody"
    }
