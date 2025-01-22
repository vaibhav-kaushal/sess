#!/usr/bin/env zsh

# function sess() {
# If the environment variable has been set and the command was called without an argument
# then we need to display the session name
if [[ $# -eq 0 ]] && [[ -v ZSH_SESSION_NAME ]]; then
	echo "Current session: $ZSH_SESSION_NAME"
	return 0
fi

# We are processing arguments
# Check if everything is correct
# if ! sess:startup_check "manual_defence"; then
if ! source ${0:A:h}/startup_check.zsh "manual_defence"; then
	echo ""
	echo "Startup checks failed"

	return 1
fi

# Check if editinit was called
if (utils:argument_exists_or_not '--editinit' $@); then
	source ${0:A:h}/editinit.zsh
	return 0
fi

# Handle listing sessions
__opt_ls=0       # listing option supplied?
__opt_ls_type="" # Listing type requested by user

# Check that listing argument is conflicting with something else
if (utils:args_do_conflict '-c' '-l' $@) || (utils:args_do_conflict '--create' '-l' $@) || (utils:args_do_conflict '-j' '-l' $@) || (utils:args_do_conflict '--join' '-l' $@) || (utils:args_do_conflict '-e' '-l' $@) || (utils:args_do_conflict '--end' '-l' $@) || (utils:args_do_conflict '-D' '-l' $@) || (utils:args_do_conflict '--delete' '-l' $@); then
	echo "Cannot do listing with any other action"
	#sess:usage
	source ${0:A:h}/help.zsh
	return 9
fi

if (utils:argument_exists_or_not '-l' $@); then
	__opt_ls=1
	__opt_ls_type=$(utils:get_argument_value '-l' $@)
fi

if [ $__opt_ls -eq 1 ]; then
	if [ -z "$__opt_ls_type" ]; then
		echo "List filter not supplied."
		#sess:usage
		source ${0:A:h}/help.zsh
		return 8
	else
		__curr_dir=$(pwd)
		__sess_list=""
		__sess_found=1
		__nonomatch_was_enabled=1

		case $__opt_ls_type in
		active | a)
			cd $ZSHY_SESS_DATA_PATH

			echo "Active Sessions:"
			echo "~~~~~~~~~~~~~~~~"

			if utils:searchopt "nonomatch"; then
				__nonomatch_was_enabled=1
			else
				__nonomatch_was_enabled=0
				# nonomatch is not enabled.
				# enable nonomatch
				setopt nonomatch
			fi

			__sess_list=$(ls -d active.* 2>/dev/null)

			if [ $? -ne 0 ]; then
				if [ $__nonomatch_was_enabled -eq 0 ]; then
					# nonomatch was originally not enabled.
					# So disable nonomatch
					unsetopt nonomatch
				fi

				echo "No active sessions found"
				return 3
			fi

			if [ $__nonomatch_was_enabled -eq 0 ]; then
				# nonomatch was originally not enabled.
				# So disable nonomatch
				unsetopt nonomatch
			fi

			while
				IFS=$"\n"
				read -r i
			do
				echo $i | sed -e 's/active.//g'
			done <<<$__sess_list

			cd $__curr_dir
			return 0
			;;
		ended | e)
			cd $ZSHY_SESS_DATA_PATH

			echo "Ended Sessions:"
			echo "~~~~~~~~~~~~~~~"

			if utils:searchopt "nonomatch"; then
				__nonomatch_was_enabled=1
			else
				__nonomatch_was_enabled=0
				# nonomatch is not enabled.
				# enable nonomatch
				setopt nonomatch
			fi

			__sess_list=$(ls -d ended.* 2>/dev/null)

			if [ $? -ne 0 ]; then
				if [ $__nonomatch_was_enabled -eq 0 ]; then
					# nonomatch was originally not enabled.
					# So disable nonomatch
					unsetopt nonomatch
				fi

				echo "No ended sessions found"
				return 3
			fi

			if [ $__nonomatch_was_enabled -eq 0 ]; then
				# nonomatch was originally not enabled.
				# So disable nonomatch
				unsetopt nonomatch
			fi

			while
				IFS=$"\n"
				read -r i
			do
				echo $i | sed -e 's/ended.//g'
			done <<<$__sess_list

			cd $__curr_dir
			return 0
			;;
		live | l)
			cd $ZSHY_SESS_DATA_PATH

			echo "Live sessions:"
			echo "~~~~~~~~~~~~~~"

			if utils:searchopt "nonomatch"; then
				__nonomatch_was_enabled=1
			else
				__nonomatch_was_enabled=0
				# nonomatch is not enabled.
				# enable nonomatch
				setopt nonomatch
			fi

			__sess_list=$(ls -d active.* 2>/dev/null)

			if [ $? -ne 0 ]; then
				if [ $__nonomatch_was_enabled -eq 0 ]; then
					# nonomatch was originally not enabled.
					# So disable nonomatch
					unsetopt nonomatch
				fi

				echo "No live sessions found"
				return 3
			fi

			if [ $__nonomatch_was_enabled -eq 0 ]; then
				# nonomatch was originally not enabled.
				# So disable nonomatch
				unsetopt nonomatch
			fi

			__at_least_one_live_session=0

			while
				IFS=$"\n"
				read -r i
			do
				cd "${ZSHY_SESS_DATA_PATH}/${i}"

				if [ -f ./session_in_use ]; then
					existing_session_lock_value=$(cat ./session_in_use)
					if [[ $existing_session_lock_value -ne 0 ]]; then
						echo $i | sed -e 's/active.//g'
						__at_least_one_live_session=1
					fi
				else
					echo "$i is a Corrupted session -- Lock file not found."
				fi
			done <<<$__sess_list

			if [[ $__at_least_one_live_session -eq 0 ]]; then
				echo "No live sessions!"
			fi

			cd $__curr_dir
			return 0
			;;
		all | A)
			cd $ZSHY_SESS_DATA_PATH

			echo "All Sessions (prefixed with state):"
			echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

			if utils:searchopt "nonomatch"; then
				__nonomatch_was_enabled=1
			else
				__nonomatch_was_enabled=0
				# nonomatch is not enabled.
				# enable nonomatch
				setopt nonomatch
			fi

			__sess_list=$(ls -d active.* 2>/dev/null)

			if [ $? -ne 0 ]; then
				__sess_found=0
			fi

			while
				IFS=$"\n"
				read -r i
			do
				echo $i
			done <<<$__sess_list

			__sess_list=$(ls -d ended.* 2>/dev/null)

			if [ $? -ne 0 ] && [[ $__sess_found -eq 0 ]]; then
				if [ $__nonomatch_was_enabled -eq 0 ]; then
					# nonomatch was originally not enabled.
					# So disable nonomatch
					unsetopt nonomatch
				fi
				echo "No sessions found!"
				return 3
			fi

			if [ $__nonomatch_was_enabled -eq 0 ]; then
				# nonomatch was originally not enabled.
				# So disable nonomatch
				unsetopt nonomatch
			fi

			while
				IFS=$"\n"
				read -r i
			do
				echo $i
			done <<<$__sess_list

			cd $__curr_dir
			return 0
			;;
		*)
			echo "Unknown list type supplied"
			#sess:usage
			source ${0:A:h}/help.zsh
			return 4
			;;
		esac
	fi
fi

# Handle creation, joining and ending of session
__opt_cs=0 # option create session
__opt_js=0 # option join session
__opt_es=0 # option end session
__opt_ds=0 # option delete session

__addval=0 # To add the results and reach a conclusion
__sess_name=""

if utils:argument_exists_or_not '-c' $@ && utils:argument_exists_or_not '--create' $@; then
	# Both longform and shortform passed.
	echo "Please use either -c or --create. Both cannot be used at once."
	#sess:usage
	source ${0:A:h}/help.zsh
	return 10
elif utils:argument_exists_or_not '-c' $@ || utils:argument_exists_or_not '--create' $@; then
	# Either longform or shortform passed
	__opt_cs=1

	if utils:argument_exists_or_not '-c' $@; then
		__sess_name=$(utils:get_argument_value '-c' $@)
	elif utils:argument_exists_or_not '--create' $@; then
		__sess_name=$(utils:get_argument_value '--create' $@)
	fi
fi

if utils:argument_exists_or_not '-j' $@ && utils:argument_exists_or_not '--join' $@; then
	echo "Please use either -j or --join. Both cannot be used at once."
	#sess:usage
	source ${0:A:h}/help.zsh
	return 11
elif utils:argument_exists_or_not '-j' $@ || utils:argument_exists_or_not '--join' $@; then
	__opt_js=1

	if utils:argument_exists_or_not '-j' $@; then
		__sess_name=$(utils:get_argument_value '-j' $@)
	elif utils:argument_exists_or_not '--join' $@; then
		__sess_name=$(utils:get_argument_value '--join' $@)
	fi

	# Should we loop and keep the session on?
	if utils:argument_exists_or_not '--loop' $@; then
		sess_join_loop="y"
	fi

fi

if utils:argument_exists_or_not '-e' $@ && utils:argument_exists_or_not '--end' $@; then
	echo "Please use either -e or --end. Both cannot be used at once."
	return 13
elif utils:argument_exists_or_not '-e' $@ || utils:argument_exists_or_not '--end' $@; then
	__opt_es=1

	if utils:argument_exists_or_not '-e' $@; then
		__sess_name=$(utils:get_argument_value '-e' $@)
	elif utils:argument_exists_or_not '--end' $@; then
		__sess_name=$(utils:get_argument_value '--end' $@)
	fi
fi

if utils:argument_exists_or_not '-D' $@ && utils:argument_exists_or_not '--delete' $@; then
	echo "Please use either -D or --delete. Both cannot be used at once."
	return 13
elif utils:argument_exists_or_not '-D' $@ || utils:argument_exists_or_not '--delete' $@; then
	__opt_ds=1

	if utils:argument_exists_or_not '-D' $@; then
		__sess_name=$(utils:get_argument_value '-D' $@)
	elif utils:argument_exists_or_not '--delete' $@; then
		__sess_name=$(utils:get_argument_value '--delete' $@)
	fi
fi

__addval=$((__opt_cs + __opt_js + __opt_es + __opt_ds))

# echo "addval= $addval"

if [ $__addval -gt 1 ]; then
	pr red "Malformed operations. Check usage:"
	echo ""
	#sess:usage
	source ${0:A:h}/help.zsh
	return 20
elif [ $__addval -eq 0 ]; then
	pr red "No operation supplied!"
	echo ""
	#sess:usage
	source ${0:A:h}/help.zsh
	return 20
fi

# Check if session name was empty (in case someone supplied the operation but not the session name)
if [ -z "$__sess_name" ]; then
	pr red "Session name was not supplied. Check usage:"
	#sess:usage
	source ${0:A:h}/help.zsh
	return 21
fi

# Take the action!

if [ $__opt_cs -eq 1 ]; then
	# New session is to be created
	echo "Creating new session $__sess_name"
	source ${0:A:h}/create.zsh $__sess_name
fi

if [ $__opt_js -eq 1 ]; then
	# Existing session is to be joined
	source ${0:A:h}/join.zsh $__sess_name

	if [[ $sess_join_loop = "y" ]]; then
		# Let's loop
		sess_join_limit=10
		n=1
		while [[ $n -le $sess_join_limit ]]; do
			pr blue "--loop was supplied when joining the session. It will be rejoined $(($sess_join_limit - $n)) times more."
			source ${0:A:h}/join.zsh $__sess_name
			let n=$n+1
		done
	fi
fi

if [ $__opt_es -eq 1 ]; then
	# Session needs to be ended
	source ${0:A:h}/end.zsh $__sess_name
fi

if [ $__opt_ds -eq 1 ]; then
	# Session needs to be deleted
	source ${0:A:h}/delete.zsh $__sess_name
fi

return 0
# }

# function sess:create() {
# 	# Check that the session already exists or not
# 	if [ -d "${ZSHY_SESS_DATA_PATH}/active.${1}" ]; then
# 		echo "An active session with that name already exists"
# 		echo "Please select a new name for the session"
# 		return 31
# 	fi

# 	if [ -d "${ZSHY_SESS_DATA_PATH}/ended.${1}" ]; then
# 		echo "An ended session with that name already exists."
# 		echo "Please select a new name for the session"
# 		return 32
# 	fi

# 	# All fine. create the session directory
# 	mkdir -p "${ZSHY_SESS_DATA_PATH}/active.${1}"
# 	# And the history file
# 	touch "${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt"

# 	# Create lock file
# 	touch "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"

# 	# Put 0 in it
# 	echo "0" >"${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"

# 	# Create the session initalization file
# 	touch "${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"
# 	echo "#!/usr/bin/env zsh" >>"${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"

# 	# Insert the command to change the HISTFILE to the newly created history file.
# 	#   We do this because just setting the HISTFILE variable and launching the ZSH shell might not work!
# 	#   This is a known behavior with oh-my-zsh.
# 	echo "fc -p ${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" >>"${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"

# 	# Put out the message
# 	pr blue "Init file created. If you want to customize the startup of this session, run:"
# 	pr blue white "sess --editinit"
# 	echo ""
# 	echo "Ensure that you have this line at the bottom of your .zshrc file:"
# 	echo "[[ -v ZSH_SESSION_INIT_FILE ]] && source \"\$ZSH_SESSION_INIT_FILE\""

# 	# and join the session
# 	source ${0:A:h}/join.zsh $1
# }

# This function allows you to edit a session's init.sh file
# function sess:editinit() {
# 	if [[ ! -v ZSH_SESSION_NAME ]]; then
# 		pr red "Not inside an active session."
# 		echo "Please join a session first."
# 		return 40
# 	fi

# 	if [ ! -d "${ZSHY_SESS_DATA_PATH}/active.${ZSH_SESSION_NAME}" ]; then
# 		pr red "Active session's storage directory is not present!!!!!"
# 		pr red "!!! ABORTING !!!"
# 		return 39
# 	fi

# 	$EDITOR "${ZSHY_SESS_DATA_PATH}/active.${ZSH_SESSION_NAME}/init.sh"
# }

# function sess:join() {
# 	# If we are already in a session, we should get into another session
# 	if [[ -v ZSH_SESSION_NAME ]]; then
# 		echo "Cannot join another session while one is active!"
# 		echo "Already in session \"$ZSH_SESSION_NAME\".";
# 		return 40
# 	fi

# 	if [ -d "${ZSHY_SESS_DATA_PATH}/ended.${1}" ]; then
# 		echo "An ended session with that name already exists."
# 		echo "Cannot join an ended session"
# 		return 33
# 	fi

# 	# Check that the session exists and is active.
# 	if [ ! -d "${ZSHY_SESS_DATA_PATH}/active.${1}" ]; then
# 		echo "No session with that name is active."
# 		echo "Please create a session with that name first."
# 		return 34
# 	elif [ ! -f "${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" ]; then
# 		echo "Session exists but history file was not found in path."
# 		echo "It appears that the session was corrupted."
# 		echo "Please create a new session with a different name."
# 		return 35
# 	fi

# 	# Local session_id & final value
# 	local session_id
# 	local final_value
# 	session_id=$(( $(date +%s) % 1580000000 ))

# 	# Value in the lock file
# 	local existing_session_lock_value
# 	existing_session_lock_value=$(cat "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use")

# 	final_value=$(( session_id + existing_session_lock_value ))

# 	echo "$final_value" > "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"

# 	echo "Joining session $1"

# 	# Prevent error message
# 	touch "${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"

# 	# All fine. Join session.
# 	# ZSH_SESSION_NAME=$1 HISTFILE="${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" ZSH_SESSION_INIT_FILE="${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh" zsh --hist-ignore-space
# 	ZSH_SESSION_NAME=$1 ZSH_SESSION_INIT_FILE="${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh" zsh --hist-ignore-space

# 	echo "Exited from session $1"

# 	# Session has ended. Reduce the value in the lock file
# 	existing_session_lock_value=$(cat "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use")
# 	final_value=$(( existing_session_lock_value - session_id ))
# 	echo "$final_value" > "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"
# }

# function sess:end() {
# 	if [ -d "${ZSHY_SESS_DATA_PATH}/ended.${1}" ]; then
# 		echo "An ended session with that name already exists."
# 		echo "Cannot end an already ended session"
# 		return 36
# 	fi

# 	if [ ! -d "${ZSHY_SESS_DATA_PATH}/active.${1}" ]; then
# 		echo "No session with that name is active."
# 		echo "Cannot end a non-existent session"
# 		return 37
# 	elif [ ! -f "${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" ]; then
# 		echo "Session exists but history file was not found in path."
# 		echo "It appears that the session was corrupted."
# 		echo "We will NOT END the session to allow debugging and correction."
# 		return 38
# 	fi

# 	# Check the lock file value and if it is 0, end the session
# 	local existing_session_lock_value
# 	existing_session_lock_value=$(cat "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use")

# 	if [ $existing_session_lock_value -gt 0 ]; then
# 		echo "Cannot end a session currently in use."
# 		echo "It appears that the session is in use in another terminal."
# 		echo "Please exit all shells using the session and retry."
# 		echo "Run 'echo \$ZSH_SESSION_NAME' in a shell to check session name (if it's using session facility)"
# 		return 39
# 	else
# 		# We should end the session
# 		mv "${ZSHY_SESS_DATA_PATH}/active.${1}" "${ZSHY_SESS_DATA_PATH}/ended.${1}"
# 		echo "Session $1 ended!"
# 	fi
# }

# function sess:delete() {
# 	if [ -d "${ZSHY_SESS_DATA_PATH}/active.${1}" ]; then
# 		pr red "Cannot delete an active session!"
# 		echo "Please end the session and try again."
# 		return 46
# 	fi

# 	if [ ! -d "${ZSHY_SESS_DATA_PATH}/ended.${1}" ]; then
# 		pr red "No such session. Cannot delete a non-existent session!"
# 		return 47
# 	fi

# 	pr blue "Are you sure?"
# 	pr blue "-------------"

# 	read -k1 "choice?Are you sure you want to delete session '${1}'? [y/n]"
# 	if [[ $choice = "y" || $choice = "Y" ]]; then
# 		echo ""
# 		pr red "Deleting session"
# 		rm -r "${ZSHY_SESS_DATA_PATH}/ended.${1}"
# 		pr green "...done"
# 	else
# 		pr blue "You opted for not deleting the session."
# 		pr blue "!!! Aborting !!!"
# 		return 48
# 	fi

# 	return 0
# }

# function sess:usage() {
# 	echo "Usage: You can use sess in one of the following ways:"
# 	echo ""
# 	echo "sess MGMT_OPERATION sess_name"
# 	echo "sess -l LIST_TYPE"
# 	echo "sess --editinit"
# 	echo ""
# 	echo "MGMT_OPERATION can be one of:"
# 	echo "  -c (or --create)  Creates a new session with sess_name as its name."
# 	echo "                    Created session will be joined immediately"
# 	echo "  -j (or --join)    Joins the session with sess_name. The session must already exist."
# 	echo "                    Adding '--loop' after the session name will rejoin the session"
# 	echo "                      for upto 10 quits."
# 	echo "  -e (or --end)     Ends the session with sess_name."
# 	echo "  -D (or --delete)  Deletes an ended session with sess_name from disk."
# 	echo "  --editinit        Opens nano to let you edit the sess_name's init.sh file"
# 	echo ""
# 	echo "LIST_TYPE can be one of:"
# 	echo "  a (or active)     For listing active sessions"
# 	echo "  l (or live)       For listing live sessions"
# 	echo "                    Live sessions are active sessions running in a terminal right now"
# 	echo "  e (or ended)      For listing ended sessions"
# 	echo "  A (or all)        For listing all sessions"
# 	echo ""
# 	echo "The --editinit option opens nano to let you edit the active session's init.sh file"
# 	echo "  This option requires that you are already inside the session whose init file you want to edit."
# }

# function sess:startup_check() {
# 	if [ $# -lt 1 ]; then
# 		echo "You are not supposed to call this command manually"
# 		return 100
# 	fi

# 	# Check if the variable is set
# 	if [[ ! -v ZSHY_SESS_DATA_PATH ]]; then
# 		echo "ZSHY_SESS_DATA_PATH is not set."
# 		echo "Sessions needs a directory to store sessions data."
# 		echo "Create the directory and set ZSHY_SESS_DATA_PATH to that value."
# 		return 1
# 	fi

# 	# Check that the directory exists
# 	if [ -e "$ZSHY_SESS_DATA_PATH" ]; then
# 		# Path exists
# 		# Check if it is a file.
# 		if [ -f "$ZSHY_SESS_DATA_PATH" ]; then
# 			# It is a file.
# 			echo "ZSHY_SESS_DATA_PATH points to a file."
# 			echo "Please make sure that it points to a directory."
# 			return 2
# 		fi

# 		# Check that it is not a symbolic link
# 		if [ -d "$ZSHY_SESS_DATA_PATH" ]; then
# 			if [ -L "$ZSHY_SESS_DATA_PATH" ]; then
# 				echo "ZSHY_SESS_DATA_PATH is a symlink to a directory."
# 				echo "Please make sure that it points to a directory, not to a symlink."
# 				return 2
# 			fi
# 		else
# 			echo "ZSHY_SESS_DATA_PATH points to an address which is not a directory."
# 			echo "Please make sure that it points to a directory."
# 			return 4
# 		fi
# 	else
# 		echo "ZSHY_SESS_DATA_PATH points to a non-existent location."
# 		echo "Sessions needs a directory to store sessions data."
# 		echo "Create the directory and set ZSHY_SESS_DATA_PATH to that value."

# 		echo "Run this to create the directory:"
# 		echo ""
# 		echo "mkdir -p $ZSHY_SESS_DATA_PATH"

# 		return 5
# 	fi

# 	return 0
# }

# function sess_help() {
# 	sess:usage
# }

# function sess_oneliner() {
# 	echo "sess: Session management with ZSH!!"
# }
