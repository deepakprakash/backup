#!/bin/bash

launchctl unload ~/Library/LaunchAgents/local.backup.trigger.plist

rm ~/Library/LaunchAgents/local.backup.trigger.plist
rm /usr/local/bin/trigger_backup.sh

echo "Uninstall complete."
