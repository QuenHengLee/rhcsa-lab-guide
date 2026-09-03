# RHCSA practice labs

    lab list                 list every exercise
    lab describe <name>      read the task, change nothing
    lab start <name>         reset + prepare the environment, then show the task
    lab grade <name>         check your work, item by item
    lab finish <name>        remove everything the exercise created

`lab` re-runs itself through sudo, so run it as `student` - no need to type
sudo yourself.

## The machines

    servera.lab.example.com   192.168.56.10    where the exercises are done
    serverb.lab.example.com   192.168.56.11    peer node (NFS server, etc.)

    student / student         passwordless sudo
    root    / student

## The disks

    /dev/sda        20 GiB    the system disk - never touched by any exercise
    /dev/nvme0n1     8 GiB    blank practice disk
    /dev/nvme0n2     8 GiB    blank practice disk

The practice disks sit on a separate NVMe controller on purpose. Linux does
not guarantee stable sd* names across boots, so putting them in a different
namespace makes it impossible to confuse them with the system disk. Every
destructive operation in the lab tooling also refuses to run against
whichever disk currently holds the root filesystem.

Volume group `rl` is left with about 4.4 GiB free so that logical volume
extension can be practised on the real system volumes too.

## Adding your own exercise

Drop a file in `/usr/local/share/rhcsa-labs/labs/<name>.lab` defining
`LAB_TITLE`, `LAB_TOPIC`, `LAB_NODE` and four functions: `lab_describe`,
`lab_setup`, `lab_grade`, `lab_finish`.

Inside `lab_grade` use:

  * `grade_check "<description>" '<shell expression>'` - the expression runs
    in a fresh `bash -c` with a 30 second timeout. Functions defined in your
    lab file are NOT visible there.
  * `grade_test "<description>" <function> [args]` - runs in the current
    shell, so your own helper functions work.

Helpers available from `lib/common.sh` include `lab_wipe_disk`,
`lab_fstab_remove`, `lab_fstab_has`, `lab_user_del`, `lab_group_del`,
`lab_password_is`, `lab_ensure_pkg`, `lab_on_peer` and `lab_peer_reachable`.
