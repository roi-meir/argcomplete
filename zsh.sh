#!/usr/bin/env zsh

AUTO_LOG_PATH="/tmp/log"


# TODO:
# 1. ?????? ${argv[${argv[(I)filenames]:-0}-1]} ?????

clear_log() {
	rm -f $AUTO_LOG_PATH
}

print_log() {
	cat $AUTO_LOG_PATH
}

log() {
	echo $@ >> $AUTO_LOG_PATH
}

__python_argcomplete_expand_tilde() {
    echo "${1/#\~/$HOME}"
}

__should_complete() {
	local ARGCOMPLETE=0

	local executable=$1
	local script_path=$2

    if [[ "$executable" == python* ]] || [[ "$executable" == pypy* ]]; then
        if [[ -f "$script_path" ]] && (head -c 1024 "$script_path" | grep --quiet "PYTHON_ARGCOMPLETE_OK") >/dev/null 2>&1; then
            local ARGCOMPLETE=2
            set -- $script_path
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

    return $ARGCOMPLETE
}


_zsh_python_argcomplete_global() {
	local executable=`__python_argcomplete_expand_tilde $words[1]`
	local script_path=`__python_argcomplete_expand_tilde $words[2]`
	local IFS=$(echo -e '\v')

	__should_complete $executable $script_path
	local ARGCOMPLETE=$?

	if [[ $ARGCOMPLETE == 0 ]]; then
		log "Not ours to complete"
		return 1
	fi

	if [[ $ARGCOMPLETE == 1 ]]; then
		local script_path=""
	fi

	compstate[insert]=menu

	_compskip="all"
	log "Ours to complete : $ARGCOMPLETE"

	local -x COMP_LINE="$words"
	(( COMP_POINT = 1 + ${#${(j. .)words[1,CURRENT]}} + $#QIPREFIX + $#IPREFIX + $#PREFIX ))
 	(( COMP_CWORD = CURRENT - 1))
    COMP_WORDS=( $words )
    BASH_VERSINFO=( 2 05b 0 1 release )
    [[ ${argv[${argv[(I)nospace]:-0}-1]} = -o ]] && suf=( -S '' )
    

    log "Running python script **executable=$executable** **script_path=$script_path" 

    # get result from python script
    matches=( $(_ARGCOMPLETE_IFS="$IFS" \
                 COMP_LINE="$COMP_LINE" \
                 COMP_POINT="$COMP_POINT" \
                 _ARGCOMPLETE_COMP_WORDBREAKS="$COMP_WORDBREAKS" \
                 _ARGCOMPLETE="$ARGCOMPLETE" \
                 "$executable" "$script_path" 8>&1 9>&2 1>/dev/null 2>/dev/null) )

	log "*****$matches****"

	if [ ${#matches[@]} -le "1" ]; then
      	matches=("${matches//[[:space:]]/}")
  	fi

	# matches=$val 
	# matches=("${(@s/$IFS/)matches}")
	if [[ -n $matches ]]; then
		if [[ ${argv[${argv[(I)filenames]:-0}-1]} = -o ]]; then
			log "What???"
	 	 	compset -P '*/' && matches=( ${matches##*/} )
	  		compset -S '/*' && matches=( ${matches%%/*} )
	  		compadd -U -Q -f "${suf[@]}" -a matches && ret=0
		else
	  		# comadd reference http://zsh.sourceforge.net/Doc/Release/Completion-Widgets.html#Completion-Widgets
	  		for item in "${matches[@]}"
	  		do
	  			log "\t Complete ***$item**"
	    		# -V to preserve the completion orders http://stackoverflow.com/questions/15140396/zsh-completion-order
	    		# -S to remove the trailing space after the completion. equal to 'complete -o nospace' in bash
	    		# TODO: allow user to specify the complete_opts ?
	    		compadd -U -S '' -- $item
	  		done
	  	ret=0
		fi
	fi


	return 0
}



compdef _zsh_python_argcomplete_global -first- 