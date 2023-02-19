# misc-scripts
Collection of miscellaneous scripts I cobbled together (or found on the internet and edited how I needed them) to acomplish things on different machines.

Some of them use the build-template of [Dave Jarvis](https://dave.autonoma.ca/) published under MIT License (I just renamed it to resemble what it is for me)

## Debian (and probably Ubuntu)
- start-services : starts services I use daily on my work-machines WSL2 Debian instance
- check-updates  : checks and prints how many packages are upgradeable
- backup-remote  : uses rsync in a WSL2 Debian to backup files from my Windows machine to my NAS
- backup-local   : uses rsync to backup files to a usb-drive using the towers of hanoi strategy
- fetch-github   : fetches the given local repos from github (needs a remote configured named github)

# Installation
Copy the scripts to wherever you like, make them runnable (chmod +x) and have a try.
