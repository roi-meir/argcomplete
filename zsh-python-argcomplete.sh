# Copyright 2012-2013, Andrey Kislyuk and argcomplete contributors.
# Licensed under the Apache License. See https://github.com/kislyuk/argcomplete for more info.

# Copy of __expand_tilde_by_ref from bash-completion
__python_argcomplete_expand_tilde_by_ref () {
    if [ "${!1:0:1}" = "~" ]; then
        if [ "${!1}" != "${!1//\/}" ]; then
            eval $1="${!1/%\/*}"/'${!1#*/}';
        else
            eval $1="${!1}";
        fi;
    fi
}

__python_argcomplete_expand_tilde() {
    echo "${1/#\~/$HOME}"
}

_python_argcomplete_global() {
    local executable=$1
    echo "_python_argcomplete_global" >> /tmp/lol
    executable=`__python_argcomplete_expand_tilde $executable`
    echo "_python_argcomplete_global: " '$@=' "$@" >> /tmp/lol
    local script_path=`__python_argcomplete_expand_tilde ${COMP_WORDS[1]}`
    echo "Do we need to complete ? $executable, $script_path" >> /tmp/lol

    local ARGCOMPLETE=0
    if [[ "$executable" == python* ]] || [[ "$executable" == pypy* ]]; then
        echo "In exec is python: ${COMP_WORDS[1]} " >> /tmp/lol
        if [[ -f "$script_path" ]] && (head -c 1024 "$script_path" | grep --quiet "PYTHON_ARGCOMPLETE_OK") >/dev/null 2>&1; then
            local ARGCOMPLETE=2
            echo "set ARGCOMPLETE to 2" >> /tmp/lol
            set -- "${COMP_WORDS[1]}"
        fi
    elif which "$executable" >/dev/null 2>&1; then
        local SCRIPT_NAME=$(which "$executable")
        if (type -t pyenv && [[ "$SCRIPT_NAME" = $(pyenv root)/shims/* ]]) >/dev/null 2>&1; then
            local SCRIPT_NAME=$(pyenv which "$executable")
        fi
        if (head -c 1024 "$SCRIPT_NAME" | grep --quiet "PYTHON_ARGCOMPLETE_OK") >/dev/null 2>&1; then
            local ARGCOMPLETE=1
        elif (head -c 1024 "$SCRIPT_NAME" | egrep --quiet "(PBR Generated)|(EASY-INSTALL-(SCRIPT|ENTRY-SCRIPT|DEV-SCRIPT))" \
            && python-argcomplete-check-easy-install-script "$SCRIPT_NAME") >/dev/null 2>&1; then
            local ARGCOMPLETE=1
        fi
    fi

    if [[ $ARGCOMPLETE == 1 ]]; then
        local script_path=""
    fi

    if [[ $ARGCOMPLETE == 1 ]] || [[ $ARGCOMPLETE == 2 ]]; then
        local IFS=$(echo -e '\v')
        echo "We want completion!" >> /tmp/lol
        echo "Running python script **executable=$executable** **script_path=$script_path"  >> /tmp/lol
        echo "\tCOMP_LINE=$COMP_LINE" >> /tmp/lol
        echo "\tCOMP_POINT=$COMP_POINT" >> /tmp/lol
        echo "\texecutable=$executable" >> /tmp/lol
        echo "\t_ARGCOMPLETE=$ARGCOMPLETE" >> /tmp/lol
        COMPREPLY=( $(_ARGCOMPLETE_IFS="$IFS" \
            COMP_LINE="$COMP_LINE" \
            COMP_POINT="$COMP_POINT" \
            _ARGCOMPLETE_COMP_WORDBREAKS="$COMP_WORDBREAKS" \
            _ARGCOMPLETE=$ARGCOMPLETE \
            "$executable" "$script_path" 8>&1 9>&2 1>/dev/null 2>&1) )
        if [[ $? != 0 ]]; then
            unset COMPREPLY
        fi
        # echo "${my_array[*]}"
        # echo "COMPREPLY=${COMPREPLY[*]}" >> /tmp/lol
    else
        echo "in else" >> /tmp/lol
        # type -t _completion_loader | grep -q 'function' && _completion_loader "$@"
    fi
}
#complete -o nospace -o default -o bashdefault -F _python_argcomplete_global
complete -o nospace -o default -o bashdefault -D -F _python_argcomplete_global
