#!/bin/bash
# This script is meant to be sourced
# Shellmarks (https://github.com/Bilalh/shellmarks)


# USAGE:
# ms <bookmark_name>  - Saves the current directory as "bookmark_name"
# m <bookmark_name>  - Goes (cd) to the directory associated with "bookmark_name"
# md <bookmark_name>  - Deletes the bookmark

# ml                  - Lists all available bookmarks
# ml <prefix>         - Lists the specified bookmarks starting with prefix"
# mpd <bookmark_name> - pd is the same as `g` but uses pushd
# ms                  - Saves the default directory
# m                  - Goes to the default directory
# m -                - Goes to the previous directory
# m_p <bookmark_name> - Prints the directory associated with "bookmark_name"

# Mac only (disabled on other systems)
# mo <bookmark_name>  - Open the directory associated with "bookmark_name" in Finder
# my <bookmark_name>  - Open the directory associated with "bookmark_name" in a new tab

# There is tab completion for all commands
# based of https://github.com/huyng/bashmarks

# Changes:
# - Added m prefix to all commands


# setup file to store bookmarks
if [ ! -n "$SDIRS" ]; then
	SDIRS=~/.sdirs
fi
touch $SDIRS

function __unset_dirs {
	eval `sed -e 's/export/unset/' -e 's/=.*/;/' $SDIRS | xargs`
}

function __print_pwd_on_action {
	 [ -n "$SHELLMARKS_PWD" ] &&  pwd
}

# save current directory to bookmarks
function ms {
	check_help "$1"
	_bookmark_name_valid "$@"
	if [ -z "$exit_message" ]; then
		local CURDIR="${PWD/$HOME/\$HOME}"
		if [ -z "$@" ]; then
			_purge_line "$SDIRS" "export DIR_DEFAULT="
		echo "export DIR_DEFAULT=\"$CURDIR\"" >> $SDIRS
		else
			_purge_line "$SDIRS" "export DIR_$1="
			echo "export DIR_$1=\"$CURDIR\"" >> $SDIRS
		fi
	fi
}

# jump to bookmark
function m {
	check_help $1
	source $SDIRS
	if [ -z $1 ]; then
		cd "$(eval $(echo echo $(echo \$DIR_DEFAULT)))"
		__print_pwd_on_action; $*
	elif [[ "$1" == "-" ]]; then
		cd $1;
		shift; $*
	elif [[ "$1" == ".."  || "$1" == '~' || "$1" == '/' ]]; then
		cd $1;
		__print_pwd_on_action; shift; $*
	else
		cd "$(eval $(echo echo $(echo \$DIR_$1)))"
		__print_pwd_on_action; shift; $*
	fi
	__unset_dirs
}

# pushd to bookmark
function mpd {
	check_help $1
	source $SDIRS
	if [ -z $1 ]; then
		pushd "$(eval $(echo echo $(echo \$DIR_DEFAULT)))"
		__print_pwd_on_action; $*
	elif [[ "$1" == "-" ]]; then
		pushd $1;
		shift; $*
	elif [[ "$1" == ".."  || "$1" == '~' || "$1" == '/' ]]; then
		pushd $1;
	else
		pushd "$(eval $(echo echo $(echo \$DIR_$1)))"
	fi
	__unset_dirs
}




# print bookmark
function m_p {
	check_help $1
	source $SDIRS
	echo "$(eval $(echo echo $(echo \$DIR_$1)))"
	__unset_dirs
}

# delete bookmark
function md {
	check_help $1
	_bookmark_name_valid "$@"
	if [ -z "$exit_message" ]; then
		_purge_line "$SDIRS" "export DIR_$1="
		unset "DIR_$1"
	fi
	__unset_dirs
}

if [[ "`uname`" == "Darwin" ]]; then

# open the specifed bookmark
function mo {
	if [ -z $1 ]; then
		open .
		osascript -e 'tell application "Finder"' -e 'activate' -e 'end tell'
	else
		check_help $1
		source $SDIRS
		open "$(eval $(echo echo $(echo \$DIR_$1)))"
		cd "$(eval $(echo echo $(echo \$DIR_$1)))"
		__print_pwd_on_action; shift; $*
		osascript -e 'tell application "Finder"' -e 'activate' -e 'end tell'
	fi
	__unset_dirs
}

#jump to bookmark in a new tab in the current window
function my {
	check_help $1
	source $SDIRS
	if [ -z $1 ]; then
		dst="`pwd`"
	elif [[ "$1" == "-" || "$1" == ".." || "$1" == '~' ||  "$1" == '/' ]]; then
		dst="$1";
		shift
	else
		dst="$(eval $(echo echo $(echo \$DIR_$1)))"
		shift
	fi

	if [ $BASHMARK_TERM_APP ]; then
		current_app="$BASHMARK_TERM_APP"
	else
		current_app="$(osascript -e 'tell application "System Events" to get item 1 of (get name of processes whose frontmost is true)')"
	fi
	if [ ${current_app:0:5} = "iTerm" ]; then
		osascript > /dev/null 2>&1 <<APPLESCRIPT
			tell application "${current_app}"
				tell the current terminal
					activate current session
					launch session "${SHELLMARKS_ITERM_SESSION:-Default}"
					tell current session
						# does not seem to allow multiple commands
						write text "cd $dst;"
					end tell
				end tell
			end tell
APPLESCRIPT
	else
	osascript > /dev/null 2>&1 <<APPLESCRIPT
		tell application "System Events"
				tell process "Terminal" to keystroke "t" using command down
		end tell
		tell application "Terminal"
				activate
				do script with command "cd $dst; $*" in window 1
		end tell
APPLESCRIPT

	fi
	__unset_dirs
}


fi

# print out help for the forgetful
function check_help {
	if [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ] ; then
		echo ''
		echo 's <bookmark_name>  - Saves the current directory as "bookmark_name"'
		echo 'g <bookmark_name>  - Goes (cd) to the directory associated with "bookmark_name"'
		echo 'd <bookmark_name>  - Deletes the bookmark'
		echo ''
		if [ "`uname`" = "Darwin" ]; then
			echo 'o <bookmark_name>  - Open the directory associated with "bookmark_name" in Finder'
			echo 'y <bookmark_name>  - Open the directory associated with "bookmark_name" in a new tab'
			echo ''
		fi
		echo 's                  - Saves the default directory'
		echo 'g                  - Goes to the default directory'
		echo 'l                  - Lists all available bookmarks'
		echo 'l <prefix>         - Lists the bookmark starting with "prefix"'
		echo '_p <bookmark_name> - Prints the directory associated with "bookmark_name"'
		echo 'pd <bookmark_name> - Same as "g" but uses pushd '
		if [ $SHELLMARKS_k ]; then
			echo ''
			echo "k <bookmark_name>  - Tries use 'g', if the bookmark does not exist try autojump's j"
		fi
		kill -SIGINT $$
	fi
}

# list bookmarks with dirname
alias ml='_bookmarks'
function _bookmarks {
	check_help $1
	source $SDIRS

	if [  -n "$1" ]; then
		# if color output is not working for you, comment out the line below '\033[1;34m' == "blue"
		env | sort | grep "DIR_$1" |  awk '/DIR_.+/{split(substr($0,5),parts,"="); printf("\033[1;34m%-20s\033[0m %s\n", parts[1], parts[2]);}'
		# uncomment this line if color output is not working with the line above
		# env | grep "^DIR_" | cut -c5-	 | grep "^.*=" | sort
	else
		# if color output is not working for you, comment out the line below '\033[1;34m' == "blue"
		env | sort | awk '/DIR_.+/{split(substr($0,5),parts,"="); printf("\033[1;34m%-20s\033[0m %s\n", parts[1], parts[2]);}'
		# uncomment this line if color output is not working with the line above
		# env | grep "^DIR_" | cut -c5-	 | grep "^.*=" | sort
	fi
	__unset_dirs
}

function _bookmarks_no_colour {
	source $SDIRS
	env | grep "^DIR_" | cut -c5-	 | grep "^.*=" | sort
	__unset_dirs
}

# list bookmarks without dirname
function _l {
	source $SDIRS
	env | grep "^DIR_" | cut -c5- | sort | grep "^.*=" | cut -f1 -d "="
	__unset_dirs
}

# validate bookmark name
function _bookmark_name_valid {
	exit_message=""
	if [ "$1" != "$(echo $1 | sed 's/[^A-Za-z0-9_]//g')" ]; then
		exit_message="bookmark name is not valid"
		echo $exit_message
	fi
}

# completion command
function _comp {
	local curw
	COMPREPLY=()
	curw=${COMP_WORDS[COMP_CWORD]}
	COMPREPLY=($(compgen -W '`_l`' -- $curw))
	return 0
}

# ZSH completion command
function _compzsh {
	reply=($(_l))
}

# safe delete line from sdirs
function _purge_line {
	if [ -s "$1" ]; then
		# safely create a temp file
		t=$(mktemp -t bashmarks.XXXXXX) || exit 1
		trap "rm -f -- '$t'" EXIT

		# purge line
		sed "/$2/d" "$1" > "$t"
		mv "$t" "$1"

		# cleanup temp file
		rm -f -- "$t"
		trap - EXIT
	fi
}

# bind completion command for o g,p,d,pd to _comp
if [ $ZSH_VERSION ]; then
	compctl -K _compzsh mo
	compctl -K _compzsh mg
	compctl -K _compzsh m_p
	compctl -K _compzsh md
	compctl -K _compzsh my
	compctl -K _compzsh mpd
else
	shopt -s progcomp
	complete -F _comp mo
	complete -F _comp m
	complete -F _comp m_p
	complete -F _comp md
	complete -F _comp my
	complete -F _comp mpd
fi

if [ $SHELLMARKS_k ]; then
	# Use a bookmark if it is available otherwise try to use autojump j's command
	function k {
		check_help $1

		if [ -n "$1"  ]; then
			if (grep DIR_$1 .sdirs &>/dev/null); then
				g "$@"
			else
				j "$@"
			fi
		else
			g "$@"
		fi
	}

	if [ $ZSH_VERSION ]; then
		function _compzsh_k {
			cur=${words[2, -1]}
			autojump --complete ${=cur[*]} | while read i
			do
				compadd -U "$i"
			done

			for f in `_l`;
			do
				compadd  $f
			done
		}
		compdef _compzsh_k k
	fi

fi

