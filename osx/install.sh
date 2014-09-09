#!/bin/bash

if cp -f trigger_backup.sh /usr/local/bin/; then
    echo "Copied trigger_backup.sh to /usr/local"

    if cp local.backup.trigger.plist ~/Library/LaunchAgents/; then
        echo "Installed .plist file"

        launchctl unload ~/Library/LaunchAgents/local.backup.trigger.plist
        launchctl load ~/Library/LaunchAgents/local.backup.trigger.plist
        echo "Backup Trigger Installation Complete."
    fi
fi
