#!/usr/bin/env bash
#
# core ellipsis functions

# These globals can be set by a user to use a custom ellipsis fork/set of modules
ELLIPSIS_USER="${ELLIPSIS_USER:-zeekay}"
ELLIPSIS_REPO="${ELLIPSIS_REPO:-https://github.com/$ELLIPSIS_USER/ellipsis}"
ELLIPSIS_MODULES_URL="${ELLIPSIS_MODULES_URL:-https://raw.githubusercontent.com/$ELLIPSIS_USER/ellipsis/master/available-modules.txt}"

# platform detection
ellipsis.platform() {
    uname | tr '[:upper:]' '[:lower:]'
}

# backup existing file, ensuring you don't overwrite existing backups
ellipsis.backup() {
    original="$1"
    backup="$original.bak"
    name="${original##*/}"

    # check for broken symlinks
    if [ "$(find -L "$original" -maxdepth 0 -type l 2>/dev/null)" != "" ]; then
        broken=$(readlink "$original")

        if [ "$(echo "$broken" | grep .ellipsis)" != "" ]; then
            # silently remove old broken ellipsis symlinks
            rm "$original"
        else
            # notify user we're removing a broken link
            echo "rm ~/$name (broken link to $broken)"
            rm "$original"
        fi

        return
    fi

    if [ -e "$original" ]; then
        # remove, not backup old ellipsis symlinked files
        if [ "$(readlink "$original" | grep .ellipsis)" != "" ]; then
            rm "$original"
            return
        fi

        if [ -e "$backup" ]; then
            n=1
            while [ -e "$backup.$n" ]; do
                n=$((n+1))
            done
            backup="$backup.$n"
        fi

        echo "mv ~/$name $backup"
        mv "$original" "$backup"
    fi
}

# run installer scripts/install.sh in github repo
ellipsis.run_installer() {
    # case $mod in
    #     http:*|https:*|git:*|ssh:*)
    # esac
    url="https://raw.githubusercontent.com/$1/master/scripts/install.sh"
    curl -s "$url" > "$1-install-$$.sh"
    ELLIPSIS=1 sh "$1-install-$$.sh"
    rm "$1-install-$$.sh"
}

# links files in module repo into home folder
ellipsis.link_files() {
    for dotfile in $(find "$1" -maxdepth 1 -name '*' ! -name '.*' | sort); do
        # ignore containing directory, ellipsis.sh and any *.md or *.rst files
        if [ "$dotfile" != "$1" && ellipsis.sh ]; then
            name="${dotfile##*/}"
            dest="~/.$name"

            backup "$dest"

            echo linking "$dest"
            ln -s "$dotfile" "$dest"
        fi
    done
}

# Installs new ellipsis module, using install hook if one exists. If no hook is
# defined, all files are symlinked into $HOME using `ellipsis.link_files`.
#
# Following variables are available from your hook:
#   $mod_name Name of your module
#   $mod_path Path to your module
ellipsis.install() {
    case $mod in
        http:*|https:*|git:*|ssh:*)
            mod_name=$(echo "$1" | rev | cut -d '/' -f 1 | rev)
            mod_path="~/.ellipsis/modules/$mod_name"
            git.clone "$1" "$mod_path"
        ;;
        github:*)
            user=$(echo "$1" | cut -d ':' -f 2 | cut -d '/' -f 1)
            mod_name=$(echo "$1" | cut -d ':' -f 2 | cut -d '/' -f 2)
            mod_path="~/.ellipsis/modules/$mod_name"
            git.clone "https://github.com/$user/$mod_name" "$mod_path"
        ;;
        *)
            mod_name="$1"
            mod_path="~/.ellipsis/modules/$mod_name"
            git.clone "https://github.com/$ELLIPSIS_USER/dot-$mod_name" "$mod_path"
        ;;
    esac

    # source ellipsis module
    source "$mod_path/ellipsis.sh"

    # run install hook if available, otherwise link files in place
    if hash mod.install 2>/dev/null; then
        mod.install
    else
        ellipsis.link_files $mod_path
    fi
}

ellipsis.list() {
    curl -s $ELLIPSIS_MODULES_URL
}

# Run command across all modules.
ellipsis.do() {
    eval "${1}" ~/.ellipsis

    for module in ~/.ellipsis/modules/*; do
        if [ -e "$module/.ellipsis/$1" ]; then
            module_path=$module
            module=${module##*/}
            . "$module_path/.ellipsis/$1"
        fi
    done
}
