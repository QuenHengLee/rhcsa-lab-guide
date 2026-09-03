# prompt.sh — colourful, host-distinct bash prompt for RHCSA practice.
#
# Install on each practice VM:
#   sudo cp setup/prompt.sh /etc/profile.d/prompt.sh
# then log out and back in.
#
# root  -> red username + trailing #   (danger: you can break things)
# user  -> green username + trailing $
# host  -> coloured so you can tell servera from serverb at a glance.
#         Edit the COLOUR below per machine: 36=cyan, 33=yellow,
#         35=magenta, 32=green, 34=blue.

_HOSTCOLOUR=36      # <-- change per machine (e.g. 33 on the second node)

if [ "$EUID" -eq 0 ]; then
    _uc='\[\e[1;31m\]'      # root: red
else
    _uc='\[\e[1;32m\]'      # user: green
fi
PS1="[${_uc}\u\[\e[0m\]@\[\e[1;${_HOSTCOLOUR}m\]\h\[\e[0m\] \[\e[1;34m\]\W\[\e[0m\]]\\$ "
unset _uc _HOSTCOLOUR
