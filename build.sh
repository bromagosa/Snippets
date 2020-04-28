#!/usr/bin/env bash

#   ========
#   Snippets
#   ========
#
#   Snippets is Not (In Principle) a Perfect, Exhaustive Template System
#
#   Site builder
#
#   written by Bernat Romagosa
#   bernat@romagosa.work
#
#   Copyright (C) 2019 by Bernat Romagosa
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# parse parameters
while echo $1 | grep ^- > /dev/null; do eval $( echo $1 | sed 's/-//g' | sed 's/=.*//g' | tr -d '\012')=$( echo $1 | sed 's/.*=//g' | tr -d '\012'); shift; done

# platform specific argument tweaks.
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    stat_find_param='-c'
elif [[ "$OSTYPE" == "darwin"* ]]; then
    stat_find_param='-f'
fi

# Generate 16 random characters
# See https://unix.stackexchange.com/a/230676
function random16() {
    echo $(LC_ALL=C tr -dc 'a-z' < /dev/urandom | head -c 16)
}

# iterate over all .snp page descriptor files
function build() {
    mkdir -p www
    for page in `ls pages/*.snp`; do
        echo "Building $page..."

        # create an html file with the same name as the descriptor file
        # see https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion
        filename="${page#pages/}"
        html=www/"${filename%.*}".html
        rm -f $html
        touch $html

        # process all descriptors in the descriptor file
        while read -r descriptor
        do
            # check whether the current line defines parameter values
            if [[ $descriptor == @param* ]]; then
                # we remove everything after "@param " and execute it,
                # then we jump to the next line
                eval "export ${descriptor#@param }"
                continue
            fi

            # find the template(s) matching the descriptor, possibly more
            # than one per line, separated by semicolons
            declare -a template_names="(${descriptor//;/ })";
            rm -f tmp.html
            for template in ${template_names[*]}; do
                # replace @include inside a template, and evaluate any @param
                include_pattern='(.*)@include=(.*)'
                param_pattern='(.*)@param(.*)'
                current_input_file="templates/$template.tmp"
                current_output_file=".temp.`random16`"
                function parse_includes() {
                    while IFS= read line; do
                        if [[ $line =~ $include_pattern ]]; then
                            # recursively include file, substituting any params
                            envsubst < "templates/${line#*@include=}.tmp" >> $current_output_file
                            current_input_file=$current_output_file
                            current_output_file=".temp.`random16`"
                            parse_includes
                        elif [[ $line =~ $param_pattern ]]; then
                            # evaluate any params found
                            eval "export ${line#@param }"
                        else
                            echo "$line" >> $current_output_file
                        fi
                    done < $current_input_file
                }

                parse_includes

                # append to the temporary HTML file, evaluating any possible params
                envsubst < $current_output_file >> tmp.html
                rm -f .temp.*
            done

            if grep -q @content $html; then
                # replace the @content string for the contents of the template file
                if [[ "$OSTYPE" == "linux-gnu" ]]; then
                    sed -e '/@content/ {' -e 'r tmp.html' -e 'd' -e '}' -i $html
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -e '/@content/ {' -e 'r tmp.html' -e 'd' -e '}' -i ''  $html
                fi
            else
                cat tmp.html >> $html
            fi

            # fix char encoding in case sed has messed it up
            if [[ "$OSTYPE" == "linux-gnu" ]]; then
                iconv -f `file -i $html | cut -f2 -d=` -t utf-8 $html -o iconv.out
                mv -f iconv.out $html
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                iconv -f `file -I $html | cut -f2 -d=` -t UTF-8 $html > iconv.out
                mv -f iconv.out $html
            fi
        done < "$page"
    done

    # copy over all static files
    cp -R static/* www

    rm -f tmp.html
    rm -f iconv.out
    echo "Done."
}

build

if test -n "$serve" -o -n "$s"; then
    port=8080

    if [[ $serve == ?(-)+([0-9]) ]]; then
        port=$serve
    elif [[ $s == ?(-)+([0-9]) ]]; then
        port=$s
    fi

    function runserver() {
        (cd www; exec -a httpserver $@ &)
    }

    pkill -f httpserver
    if test -n `which http-server`; then
        runserver http-server -p $port
    elif test -n `which python`; then
        runserver python -m SimpleHTTPServer $port
    elif test -n `which ruby`; then
        runserver ruby -run -ehttpd . -p$port
    elif test -n `which php`; then
        runserver php -S 127.0.0.1:$port
    else
        echo "Could not find a way to serve static files. Please install one of the following:"
        echo
        echo "Ruby"
        echo "Python"
        echo "NodeJS http-server module"
        echo "PHP"
    fi
elif test -n "$S"; then # https is only supported by http-server
    (cd www; exec -a httpserver http-server -S -p 443 &)
fi

# watch and build on any file change

if test -n "$watch" -o -n "$w"; then
    declare -A lasttimes
    while sleep 1; do
        # ignores hidden files and dirs (./.*), the www and docs folders, and VIM .swp files
        for file in `find . -type f | grep -v "^\./\." | grep -v "./www/.*" | grep -v "./docs/.*" | grep -v "\.swp$"`; do
            time=`stat $stat_find_param %Z "$file"`

            if [ -z ${lasttimes[$file]} ]; then
                lasttimes["$file"]=$time
            fi

            if [ "$time" != "${lasttimes[$file]}" ]; then
                echo "$file changed."
                echo "Rebuilding..."
                build
                lasttimes["$file"]=$time
                break
            fi
            lasttimes["$file"]=$time
        done
    done
fi
