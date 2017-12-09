#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0


_xmingw_env ()
{
local cur opts
	COMPREPLY=""
	cur="${COMP_WORDS[COMP_CWORD]}"
	opts="win32 win64"

	COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	return 0
}
#complete -F _env env.sh


_xmingw_cross ()
{
local cur prev opts
	COMPREPLY=""
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--archflags --cflags --ldflags --help --version"

	if [[ ${cur} == -* ]]
	then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}
#complete -F _xmingw_cross cross


_xmingw_package ()
{
local cur prev opts
	COMPREPLY=""
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--deps --dependencies --optdeps --optional-dependencies --license --feature --os --range -D --archives --log-path --script-path --install-path -h --help --version"

	if [[ "${prev}" == "-D" ]]
	then
		compopt -o nospace
		COMPREPLY=( $(compgen -W "VER= REV=" -- ${cur}) )
		return 0
	elif [[ "${prev}" == "--range" ]]
	then
		COMPREPLY=( $(compgen -W "patch configure make pack" -- ${cur}) )
		return 0
	elif [[ "${cur}" == -* ]]
	then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	else
       # Unescape space
       cur=${cur//\\ / }
       # Expand tilder to $HOME
       [[ ${cur} == "~/"* ]] && cur=${cur/\~/$HOME}
       # Show completion if path exist (and escape spaces)
       local files dirs
		local curdir="$PWD"
		if [[ ! ${cur} == "./"* && ! ${cur} == "/"* ]]
		then
			cd "${XLOCAL}/src/packaging"
		fi

		dirs=($(compgen -o dirnames "${cur}"))
		if [[ -e "${dirs[0]}" ]]
		then
			compopt -o nospace
			COMPREPLY=( "${dirs[@]// /\ }/" )
		fi
		compopt +o filenames
		files=("${cur}"*.sh)
		[[ -e "${files[0]}" ]] && 
			COMPREPLY=( "${files[@]// /\ }" )

		cd "${curdir}"
	fi
}
complete -F _xmingw_cross cross
complete -F _xmingw_package package


