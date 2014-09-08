# Backup Strategy


## Primary Backup

Whenever `<PRI_VOL>` is connected and sync is initiated, rsync backs up everything under `~/Depot` to `<PRI_VOL>/Depot`.

Be aware that `--delete` option is provided to `rsync` and hence anything that is deleted or missing in the source will be deleted from the destination as well. However, since the `--backup` option is also specified, a copy is kept in the destination directory `<PRI_VOL>/Depot/.Backup`.

Some exclusions are specified, notably:

- `/*/Archive`

  The `Archive` directories in the second level of `Depot` (Eg: `Photos/Archive`, `Photography/Archive`, etc) in the backups are special. They are usually NOT present or are empty in local source, but are present in the backups. The `Archive` directory in the backups contain most of the data, ie, stuff that is currently not available or necesary in the local source, but which need to stored forever. They are usually populated by directly moving the files no longer needed on local machine to the corresponding `Archive` directory in primary backup (More info in the *Clean up local machine* section under *Photography Workflow*). Hence these are ignored to make sure that `rsync` doesn't cause any undesirable behaviour on them in the primary backup.


### Clean up deleted files

To prevent the backup from growing much bigger (due to preservation of deleted items), a periodic `primary_cleanup` call needs to be done. This will clean out the `<PRI_VOL>/Depot/.Backup` directory.

Doing a secondary backup after `primary_cleanup` will clean out the deleted files in secondary as well. Be aware that doing this will mean that all backup copies of deleted files are deleted and hence will be unrecoverable.

## Secondary Backup

Whenever the primary and secondary backup disks are connected and sync is initiated, `rsync` will sync everything from `<PRI_VOL>/Depot` to `<SEC_VOL>/Depot`.

The secondary backup is a mirror of the primary backup. Since the primary backup saves deleted files using the `--backup` option, those files are also mirrored to secondary. Hence, reasonable safety is assured.

## Photography Workflow

Import photos into the `Current` directory of `Depot/Photography` of local machine using Lightroom.

- Delete completely unusable exposures from right there.
- If there are *casual/people* photos, create a corresponding directory under `Depot/Photos/Current` and quickly process and move them there.
- Process everything.
- Export the picks as near full size JPEGs to `Depot/Photography/Processed/<date>`

Initiate a sync after processing so that everything is backed up.

### Clean up local machine

After a few shoots, the disk will start to fill up. To free up the disk:

- Connect the primary backup. May complete a primary backup.
- Open Lightroom and move the processed folders directly from the local disk into the `Depot/Photography/Archive/<year>` of the primary backup volume. Same can be done to corresponding items in `Photos`.


## Photos

Photos are put into local `Depot/Photos/Current` directory. And they are usually part of the Lightroom catalog. Clean up is similar to Photography Workflow.

### Archive Mobile Photos

Or else, simply `move` items from `~/Depot/Photos/Current/Mobile` to `<PRI_VOL>/Depot/Photos/Archive/Mobile` manually. Remember that it should be `move`, and NOT `copy`.

## General Notes

- Never touch anything inside `Depot/` of either backup disks directly - unless its a reorganization of things in each `Archive` directory. Always rely on:
  - Changes being made in the source which will propagte to the backups after sync.
  - Use something like Lightroom to move things directly from the `Current` dirs to the corresponding `Archive` dirs in the primary backup.
