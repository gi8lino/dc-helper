#!/bin/sh

VERSION="0.1.0"

function ShowHelp {
    printf "%s\n" \
        "Usage: $(basename $BASH_SOURCE) [UP] [DOWN] [RESTART] [UPDATE] [CLEANUP] [GIT] | [-h|--help] | [-v|--version]" \
	    "" \
        "A little helper tool to manage directories with docker-compose files inside." \
	    "Iterate over current sub directories and execute the defined commands." \
        "It execute the commands in order you pass them to this script!" \
        "" \
        "Commands:" \
        "up                 run docker-compose up -d" \
        "down               run docker-compose down" \
        "restart            run docker-compose restart" \
        "update             try to update image" \
        "cleanup            remove old images" \
        "git                pull latest update from a git repo" \
        "" \
        "Optional Parameters" \
        "-h, --help         display this help and exit" \
        "-v, --version      output version information and exit" \
        "" \
        "created by gi8lino (2020)" \
        "https://github.com/gi8lino/dc-helper"
    	exit 0
}

shopt -s nocasematch  # set string compare to not case senstive
unset IFS

commands=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        up)
        commands+=("UP")
        shift
        ;;
        down)
        commands+=("DOWN")
        shift
        ;;
        restart)
        commands+=("RESTART")
        shift
        ;;
        git)
        commands+=("GIT")
        shift
        ;;
        update)
        commands+=("UPDATE")
        shift
        ;;
        cleanup)
        commands+=("CLEANUP")
        shift
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
    esac
done

[ ${#commands} == 0 ] && ShowHelp

 # check if it is neccessary to get image id's
 [[ " ${commands[@]} " =~ "UP" ]] || \
    [[ " ${commands[@]} " =~ "DOWN" ]] || \
    [[ " ${commands[@]} " =~ "RESTART" ]] || \
    [[ " ${commands[@]} " =~ "CLEANUP" ]] || \
    [[ " ${commands[@]} " =~ "UPDATE" ]] && docker_commands=true

IFS=$(echo -en "\n\b")  # change separetor for directories with space
for dir in $(ls -d */); do
    dir=$(basename $dir)
    echo -e "processing \033[0;35m$dir\033[0m"

    images=()   
    if [ -n "$docker_commands" ]; then
        if [ -f "$dir/docker-compose.yml" ]; then
            [ -f "$dir/.env" ] && source "$dir/.env"  # load variables from .env

            while IFS=' ', read -ra service; do
                img_url="${service[1]/\$\{DOMAIN\}/$DOMAIN}"  # substitute '${DOMAIN}' variable if set
                [[ ! $img_url =~ ":" ]] && img_url="$img_url:latest"  # add 'latest' tag if no tag is set
                img_id=$(docker images --filter=reference=$img_url | tail -n +2 | awk '{print $3}')  # get image id
                images+=("$img_url|$img_id")
            done <<< "$(grep 'image:' $dir/docker-compose.yml)"
        fi
    fi

    docker_msg=true  # to avoid multiple msg if docker-compose is found or not
    for cmd in ${commands[*]}; do
        case $cmd in
            UP|DOWN|RESTART)
            if [ -f "$dir/docker-compose.yml" ]; then 
                [ $docker_msg == true ] && echo -e "'docker-compose.yml' found" && docker_msg=false
                cd "$dir/"
                [ $cmd == "UP" ]      && echo -e "execute \033[0;35mdocker-compose up -d\033[0m"    && docker-compose up -d
                [ $cmd == "DOWN" ]    && echo -e "execute \033[0;35mdocker-compose down\033[0m"     && docker-compose down
                [ $cmd == "RESTART" ] && echo -e "execute \033[0;35mdocker-compose restart\033[0m"  && docker-compose restart
                cd ..
            else
                [ $docker_msg == true ] && echo -e "\033[0;31mno 'docker-compose.yml' found\033[0m" && docker_msg=false
            fi
            ;;
            GIT)
            [ -d "$dir/.git" ] && echo -e "git repository found" && git --git-dir="$dir/.git" pull || echo -e "\033[0;31mno git repository found\033[0m"
            ;;
            UPDATE)
            [ ${#images} != 0 ] && echo -e "update images..."
            for image in ${images[*]}; do
                IFS='|' read -ra img <<< "$image"
                [[ $(docker pull ${img[0]}) =~ "up to date" ]] && \
                        echo -e "image \033[0;35m${img[0]}\033[0m is \033[0;32mupdate to date\033[0m" 
            done
            ;;
            CLEANUP)
            [ ${#images} != 0 ] && echo -e "cleanup images..."
            for image in ${images[*]}; do
                IFS='|' read -ra img <<< "$image"
                [ ! -z "${img[1]}" ] && echo -e "remove old image \033[0;35m${img[0]}\033[0m" && docker rmi ${img[1]} || \
                        echo -e "image \033[0;35m${img}\033[0m\033[0;31m is not locally\033[0m"
            done
            ;;
        esac
    done
done

