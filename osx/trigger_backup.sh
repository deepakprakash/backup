#!/bin/zsh
source ~/.zshrc

backup_lock=/tmp/.backuplock

is_backup_locked () {
    if [ -f $backup_lock ]
    then
        return 0
    fi

    return 1
}

unlock_backup () {
    if is_backup_locked
    then
        rm $backup_lock
    fi
}

lock_backup () {
    if ! is_backup_locked
    then
        touch $backup_lock
    fi
}

if is_backup_locked; then
    # Backup is going on. Don't do anything
    echo "Lockfile found. Aborting."
    exit 1
else
    # Lock the backup so that another backup doesnt run while this is running.
    lock_backup

    # Run the primary backup. All the sanity checks are done inside the
    # `backup` script. So no need to do it here.
    if backup --primary; then
        # Successful

        # Show notification.
        terminal-notifier -title "Backup - Primary" -message "Completed primary backup."

        secondary_dest=/Volumes/$BACKUP_VOL_SECONDARY/Depot/

        # Check if the secondary volume is connected.
        if [ -d "$secondary_dest" ]; then
            # Secondary volume is present

            # Sleep for a few seconds to avoid notification and confirmation dialog
            # from popping up together. Nothing wrong in it, but simply avoids
            # too many things popping up to user at the same time.
            sleep 2

            # Ask to start secondary backup
            if confirm_dialog "Start backup to secondary?"; then
                # User clicked on 'OK'

                if backup --secondary; then
                    # Successful

                    # Show notification
                    terminal-notifier -title "Backup - Secondary" -message "Completed secondary backup."
                else
                    # Failed

                    # Show notification
                    terminal-notifier -title "Backup - Secondary" -message "Secondary backup failed. Please check logs."
                fi
            fi
        fi

    fi

    # Unlock so that backup can happen again.
    unlock_backup
fi
