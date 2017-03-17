import fcntl
import io
import os
import requests
import traceback
import subprocess
import sys
import datetime

from pathlib import Path


LOG_STREAM = io.StringIO()

def log(*args, **kwargs):

    file_arg = kwargs.pop('file', sys.stdout)

    print(*args, file=LOG_STREAM, **kwargs)
    print(*args, file=file_arg, **kwargs)


def send_email(success=True):

    status = 'Success' if success else 'Failed'

    subject = '[Log] {date} - Backup: {status}!'.format(status=status, date=datetime.date.today())

    return requests.post(
        'https://api.mailgun.net/v3/dfu.re/messages',
        auth=('api', 'key-e86fac0ce87ca37b84222c16eec3cf8c'),
        data={
            'from': 'Deefu Logger <logs@dfu.re>',
            'to': ['dp+logs@dfu.re'],
            'subject': subject,
            'text': LOG_STREAM.getvalue(),
        }
    )


def acquire_lock():
    lockfile = open(Path(os.path.expanduser('~')).joinpath('.backuplock').as_posix(), 'w')

    log('Acquiring lock... ', end='')
    fcntl.flock(lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)  # LOCK_NB is to make sure there is no blocking on lock aquisition
    log('✓')

    return lockfile


def backup_to_secondary(path_primary, path_secondary):

    # rsync -ahv /media/DP_HDD_02/Depot/ /media/DP_HDD_04/Depot/ >> /tmp/rsync2.log

    # For rsync, we need the trailing slashes for the dirs.
    path_primary = '{path}/'.format(path=path_primary)
    path_secondary = '{path}/'.format(path=path_secondary)


    command = ' '.join([
        'rsync',
        '--archive',
        '--modify-window=1',
        '--delete',
        '--backup --backup-dir="{backup_dir}" --exclude="{backup_dir}"'.format(backup_dir='.Deleted'),

        '--verbose', '--human-readable',

        path_primary,
        path_secondary,
    ])


    log('\n\nStarting back up to secondary disk: {command}'.format(command=command))

    returncode = 0

    try:
        output = subprocess.check_output(
            command,
            stderr=subprocess.STDOUT,
            shell=True,
        )
    except subprocess.CalledProcessError as e:
        output = e.output
        returncode = e.returncode

    log(output.decode())

    if returncode == 0:
        log('Backup to secondary completed... ✓')
    else:
        raise Exception('There was an error doing the backup to secondary disk.')


def backup_to_b2(path_secondary, b2_bucket, b2_path):

    command = ' '.join([
        'b2 sync',
        '--noProgress',
        '--keepDays 15',
        '--replaceNewer',
        '--compareVersions size',
        '--excludeRegex ".Deleted/*"',
        str(path_secondary),
        'b2://{bucket}/{path}'.format(bucket=b2_bucket, path=b2_path)
    ])

    log('\n\nStarting back up to B2: {command}'.format(command=command))

    returncode = 0

    try:
        output = subprocess.check_output(
            command,
            stderr=subprocess.STDOUT,
            shell=True,
        )
    except subprocess.CalledProcessError as e:
        output = e.output
        returncode = e.returncode

    log(output.decode())

    if returncode == 0:
        log('Backup to B2 completed... ✓')
    else:
        raise Exception('There was an error doing the backup to B2.')


if __name__ == '__main__':
    # args = parser.parse_args()
    # args.func(args)

    PATH_PRIMARY = Path('/media/DP_HDD_02/Depot/')
    PATH_SECONDARY = Path('/media/DP_HDD_04/Depot/')

    B2_BUCKET = 'DP-BACKUPS'
    B2_PATH = PATH_SECONDARY.name  # Get the final part of the PATH_SECONDARY.

    try:
        lockfile = acquire_lock()

        backup_to_secondary(PATH_PRIMARY, PATH_SECONDARY)

        backup_to_b2(PATH_SECONDARY, B2_BUCKET, B2_PATH)

    except Exception:
        # There was an issue. Send email with details
        log(traceback.format_exc())
        send_email(False)
        exit(1)
    else:
        send_email(True)

    #fcntl.flock(lockfile, fcntl.LOCK_UN)

