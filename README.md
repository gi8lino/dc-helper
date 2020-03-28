# dc-helper

A little helper tool to manage directories with docker-compose files inside.  

Iterate over current sub directories and execute the defined commands.
It execute the commands in order you pass them to this script!

## usage

```bash
Usage: dch.sh [UP] [DOWN] [RESTART] [UPDATE] [CLEANUP] [GIT] | [-h|--help] | [-v|--version]

Commands:
up                 run docker-compose up -d
down               run docker-compose down
restart            run docker-compose restart
update             try to update image
cleanup            remove old images
git                pull latest update from a git repo

Optional Parameters
-h, --help         display this help and exit
-v, --version      output version information and exit
```
