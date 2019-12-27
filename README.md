# dc-helper

a little helper tool for shutting down or up multiple docker container

## usage

```bash
Usage: dc.sh UP|DOWN [-u|--update] [-c|--cleanup] [-g|--git] | [-h|--help] | [-v|--version]

iterate over current sub directories and execute a 'docker-compose up -d' or 'docker-compose down'

Parameters:
UP                 run docker-compose up -d
DOWN               run docker-compose down

Optional Parameters
-u, --update       try to update image
-c, --cleanup      remove old images
-g, --git          pull latest update from a git repo
-h, --help         display this help and exit
-v, --version      output version information and exit

created by gi8lino (2019)
https://github.com/gi8lino/dc-helper
```
