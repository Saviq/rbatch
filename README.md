# rbatch
Batch processing using rclone

[rbatch](https://github.com/Saviq/rbatch) lets you automate [rclone](http://rclone.org/) runs with the help of [systemd](https://www.freedesktop.org/wiki/Software/systemd/).

Assuming you have rclone configured, getting rbatch going is as simple as:
- put [rbatch](bin/rbatch) somewhere on your $PATH
- put [rbatch@.service](systemd/rbatch%40.service) somewhere where [systemd finds it](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)
- set a few environment variables, either by putting a [.rbatch.env](rbatch.env) file in your $HOME, or via [systemd drop-ins](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Description)

Example:

    RBATCH_OPTIONS=--bwlimit=1M
    RBATCH_ALL=one-sync one-copy-Sub\\ Path
    one_SRC=remote:path
    one_DEST=/local/path

- RBATCH_OPTIONS will be passed, verbatim, to rclone.
- RBATCH_ALL is a list of operations to perform by default
- *_SRC and *_DEST are the rclone source and destination pair

Now you can start rbatch with any of:

    $ systemctl --user start rbatch@all.service
    $ systemctl --user start rbatch@one.service
    $ systemctl --user start rbatch@one-check.service # doesn't have ot be in RBATCH_ALL
    $ systemctl --user start ( systemd-escape --template=rbatch@.service "one-move-Some folder"

It will find matching subdirectories between source and destination and start other rbatch@ instances that perform a check, sync, copy or move operation on those.

See help for more information:

    $ rbatch --help

TIP: To interrupt transfers or monitor progress, you can use wildcards in systemd commands, e.g.:

    $ systemctl --user stop rbatch@*.service
    $ journalctl --user-unit rbatch@one-*.service
