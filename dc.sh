#!/bin/bash

VERSION="0.0.1"

function ShowHelp {
    printf "%s\n" \
        "Usage: $(basename $BASH_SOURCE) UP|DOWN [-u|--update] [-c|--cleanup] [-g|--git] | [-h|--help] | [-v|--version]" \
	    "" \
	    "iterate over current sub directories and execute a 'docker-compose up -d' or 'docker-compose down'" \
        "" \
        "Parameters:" \
        "UP                 run docker-compose up -d" \
        "DOWN               run docker-compose down" \
        "" \
        "Optional Parameters" \
        "-u, --update       try to update image" \
        "-c, --cleanup      remove old images" \
        "-g, --git          pull latest update from a git repo" \
        "-h, --help         display this help and exit" \
        "-v, --version      output version information and exit" \
        "" \
        "created by gi8lino (2019)" \
        "https://github.com/gi8lino/dc-helper"
    exit 0
}

shopt -s nocasematch  # set string compare to not case senstive
unset IFS

# read start parameter
while [[ $# -gt 0 ]];do
    key="$1"
    case $key in
	    up)
	    UP="TRUE"
	    shift  # pass argument
	    ;;
	    down)
	    DOWN="TRUE"
	    shift  # pass argument
	    ;;
	    -g|--git)
	    GIT="TRUE"
	    shift  # pass argument
        ;;
	    -u|--update)
	    UPDATE="TRUE"
	    shift  # pass argument
	    ;;
        -c|--cleanup)
	    CLEANUP="TRUE"
	    shift  # pass argument
	    ;;
	    -v|--version)
	    printf "$(basename $BASH_SOURCE) version: %s\n" "${VERSION}"
	    exit 0
	    ;;
	    -h|--help)
	    ShowHelp
	    ;;
	    *)  # unknown option
	    printf "%s\n" \
	       "$(basename $BASH_SOURCE): invalid option -- '$1'" \
	       "Try '$(basename $BASH_SOURCE) --help' for more information."
        exit 1
	    ;;
    esac  # end case
done

# check if both parameter are set
if [ -n "$UP" ] && [ -n "$DOWN" ]; then
    echo -e "\033[0;31myou cannot set parameter for 'UP' and 'DOWN'\033[0m" 
    exit 1
fi

# check if no parameter is set
if [ ! -n "$UP" ] && [ ! -n "$DOWN" ]; then
    echo -e "\033[0;31myou must set a parameter 'UP' or 'DOWN'\033[0m" 
    exit 1
fi

for dir in $(ls -d */); do
	cd $dir
	
	if [ ! -f "docker-compose.yml" ]; then
		echo -e "inside \033[0;31m$(basename $dir)\033[0m no 'docker-compose.yml' found"
		cd ..
		continue
	fi	

	# pull git if variable set
        if [ -n "$GIT" ]; then
		    if [ -d ".git" ]; then
        	    git pull
		    fi
        fi

	if [ -n "$UP" ]; then
        if [ -n "$UPDATE" ]; then
            # load variables from .env
            if [ -f ".env" ]; then
                source .env
            fi

            while IFS=' ', read -a input; do
                img="${input[1]}"
                old_images=$(docker images -a | grep "$img" | awk '{print $3}')  # get image id

                result=$(docker pull "${img/\$\{DOMAIN\}/$DOMAIN}")  # substitute '${DOMAIN}' variable
                
                docker-compose up -d

                if [ -n "$CLEANUP" ] && [[ ! $result =~ "up to date" ]]; then
                    for image in ${old_images[*]}; do
                        echo -e "\033[0;31mremove old image '$image'\033[0m"  #docker rmi $image
                        docker rmi $image
                    done
                fi
            done <<< "$(grep 'image:' docker-compose.yml)"
        else
            docker-compose up -d
        fi
	fi

    if [ -n "$DOWN" ]; then
        docker-compose down
    fi

	cd ..
done
