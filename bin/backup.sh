#!/bin/zsh

usage_message="
Perform specified backup.

Usage: backup [OPTION]...

--primary      Perform the primary backup.
--secondary    Perform the secondary backup.
--cleanup      Cleanup the '.Deleted' directory of primary backup that holds deleted items.
-h, --help     Show this help.
"

usage () {
    echo $usage_message
}

if [ "$1" = "" ]; then
    usage
    exit
fi

primary=
secondary=
dry=
cleanup=

while [ "$1" != "" ]; do
    case $1 in
        --primary )             primary=1
                                ;;
        --secondary )           secondary=1
                                ;;
        --dry-run )             dry=1
                                ;;
        --cleanup )             cleanup=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

common_options="-azh --progress --delete"
if [ "$dry" = "1" ]; then
    common_options="-n $common_options"
fi

primary_source=~/Depot/
primary_dest=/Volumes/$BACKUP_VOL_PRIMARY/Depot/

backup_dir=.Deleted

primary_backup () {

    # Sanity checks
    if [ ! -d "$primary_source" ]; then
        echo "The source for primary backup: $primary_source cannot be found. Aborting."
        return 1
    fi

    if [ ! -d "$primary_dest" ]; then
        echo "The destination for primary backup: $primary_dest cannot be found. Aborting."
        return 1
    fi

    local primary_options="--exclude='/*/Archive' --exclude='*.lrdata' --exclude='$backup_dir' --backup --backup-dir='$backup_dir'"

    echo "Starting primary backup.."
    eval "rsync $common_options $primary_options $primary_source $primary_dest"
}

secondary_source=$primary_dest
secondary_dest=/Volumes/$BACKUP_VOL_SECONDARY/Depot/
secondary_backup () {

    # Sanity checks
    if [ ! -d "$secondary_source" ]; then
        echo "The source for secondary backup: $secondary_source cannot be found. Aborting."
        return 1
    fi
    if [ ! -d "$secondary_dest" ]; then
        echo "The destination for secondary backup: $secondary_dest cannot be found. Aborting."
        return 1
    fi

    echo "Starting secondary backup.."
    eval "rsync $common_options $secondary_source $secondary_dest"
}

if [ "$primary" = "1" ]; then

    if primary_backup; then
        echo "Primary backup completed."
    else
        echo "Primary backup failed. Please check logs."
        exit 1
    fi
fi

if [ "$secondary" = "1" ]; then
    if secondary_backup; then
        echo "Secondary backup completed."
    else
        echo "Secondary backup failed. Please check logs."
        exit 1
    fi
fi


cleanup () {
    echo "Starting cleanup.."
    local cleanup_dir=$primary_dest$backup_dir

    if [ ! -d "$cleanup_dir" ]; then
        echo "The backup directory: $cleanup_dir cannot be found. Aborting."
        return 1
    fi

    if [ "$(ls -A $cleanup_dir)" ]; then
        rm -r $cleanup_dir/*
    else
        echo "Backup directory is already empty."
    fi
}

if [ "$cleanup" = "1" ]; then
    if cleanup; then
        echo "Cleanup on the primary backup completed. This will be reflected in secondary once a secondary backup is done."
    else
        echo "Cleanup failed. Please check logs."
        exit 1
    fi
fi

exit 0
