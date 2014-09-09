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

volume_list_previous=/tmp/.backup_vol_list.previous
volume_list_current=/tmp/.backup_vol_list.current
volume_list_diff=/tmp/.backup_vol_list.diff

# Generate an empty .previous if it doesnt exist
if [ ! -f "$volume_list_previous" ];then
    touch $volume_list_previous
fi

# List current volumes to .current. One on each line. Directories with a trailing '/'
ls -1F /Volumes/ > $volume_list_current

# Output the diff to .diff
eval "diff --unchanged-line-format= --old-line-format= --new-line-format='%L' $volume_list_previous $volume_list_current > $volume_list_diff"

mv $volume_list_previous $volume_list_previous.old

# Move the new list to previous for use in next invocation
mv $volume_list_current $volume_list_previous


if cat $volume_list_diff | grep -Ex "$BACKUP_VOL_SECONDARY/|$BACKUP_VOL_PRIMARY/"; then
    # One or both of the $BACKUP_VOL_SECONDARY, $BACKUP_VOL_PRIMARY was found
    # in the /Volumes diff. Means that one or both of the disks were connected now.
    # So continue with the backup

    if is_backup_locked; then
        # Backup is going on. Don't do anything
        echo "Lockfile found. Aborting."
        exit 1
    else
        # Lock the backup so that another backup doesnt run while this is running.
        lock_backup

        # Run the primary backup. All the sanity checks are done inside the
        # `backup` script. So no need to do it here.
        if backup --primary --dry-run; then
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

                    if backup --secondary --dry-run; then
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
else
    echo "Either a disk was ejected or newly mounted disk(s) are not a PRIMARY or SECONDARY backup volume."
fi
