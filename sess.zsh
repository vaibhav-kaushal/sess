#!/usr/bin/env zsh

function sess() {
	# If the environment variable has been set and the command was called without an argument
	# then we need to display the settion name
	if [[ $# -eq 0 ]] && [[ -v ZSH_SESSION_NAME ]]; then
		echo "Current session: $ZSH_SESSION_NAME";
		return 0
	fi

	# We are processing arguments
	# Check if everything is correct
	if ! sess:startup_check "manual_defence"; then
		echo ""
		echo "Startup checks failed"

		return 1
	fi

	# Check if editinit was called
	local opt_ei
	opt_ei=0
	if (utils:argument_exists_or_not '--editinit' $@); then
		sess:editinit
		return 0
	fi

	# Handle listing sessions
	local opt_ls # listing option supplied?
	opt_ls=0
	local opt_ls_type # Listing type requested by user
	opt_ls_type=""

	# Check that listing argument is conflicting with something else
	if (utils:args_do_conflict '-c' '-l' $@) || (utils:args_do_conflict '--create' '-l' $@) || (utils:args_do_conflict '-j' '-l' $@) || (utils:args_do_conflict '--join' '-l' $@) || (utils:args_do_conflict '-e' '-l' $@) || (utils:args_do_conflict '--end' '-l' $@) || (utils:args_do_conflict '-D' '-l' $@) || (utils:args_do_conflict '--delete' '-l' $@)
	then
			echo "Cannot do listing with any other action"
			sess:usage
			return 9
	fi

	if (utils:argument_exists_or_not '-l' $@); then
		opt_ls=1
		opt_ls_type=$(utils:get_argument_value '-l' $@)
	fi

	if [ $opt_ls -eq 1 ]; then
		if [ -z "$opt_ls_type" ]; then
			echo "List filter not supplied."
			sess:usage
			return 8
		else
			local curr_dir
			curr_dir=$(pwd)
			local sess_list
			local sess_found
			sess_found=1

			case $opt_ls_type in
				active|a)
					cd $ZSH_SESSION_PATH

					echo "Active Sessions:"
					echo "~~~~~~~~~~~~~~~~"

					local nonomatch_was_enabled
					if utils:searchopt "nonomatch"; then
						nonomatch_was_enabled=1
					else
						nonomatch_was_enabled=0
						# nonomatch is not enabled. 
						# enable nonomatch
						setopt nonomatch
					fi

					sess_list=$(ls -d active.* 2>/dev/null)

					if [ $? -ne 0 ]; then
						if [ $nonomatch_was_enabled -eq 0 ]; then
							# nonomatch was originally not enabled.
							# So disable nonomatch
							unsetopt nonomatch
						fi

						echo "No active sessions found"
						return 3
					fi

					if [ $nonomatch_was_enabled -eq 0 ]; then
						# nonomatch was originally not enabled.
						# So disable nonomatch
						unsetopt nonomatch
					fi

					while IFS=$"\n"; read -r i; do	
						echo $i | sed -e 's/active.//g'
					done <<< $sess_list

					cd $curr_dir
					return 0
					;;
				ended|e)
					cd $ZSH_SESSION_PATH

					echo "Ended Sessions:"
					echo "~~~~~~~~~~~~~~~"

					local nonomatch_was_enabled
					if utils:searchopt "nonomatch"; then
						nonomatch_was_enabled=1
					else
						nonomatch_was_enabled=0
						# nonomatch is not enabled. 
						# enable nonomatch
						setopt nonomatch
					fi

					sess_list=$(ls -d ended.* 2>/dev/null)

					if [ $? -ne 0 ]; then
						if [ $nonomatch_was_enabled -eq 0 ]; then
							# nonomatch was originally not enabled.
							# So disable nonomatch
							unsetopt nonomatch
						fi

						echo "No ended sessions found"
						return 3
					fi

					if [ $nonomatch_was_enabled -eq 0 ]; then
						# nonomatch was originally not enabled.
						# So disable nonomatch
						unsetopt nonomatch
					fi

					while IFS=$"\n"; read -r i; do	
						echo $i | sed -e 's/ended.//g'
					done <<< $sess_list

					cd $curr_dir
					return 0
					;;
				live|l)
					cd $ZSH_SESSION_PATH

					echo "Live sessions:"
					echo "~~~~~~~~~~~~~~"

					local nonomatch_was_enabled
					if utils:searchopt "nonomatch"; then
						nonomatch_was_enabled=1
					else
						nonomatch_was_enabled=0
						# nonomatch is not enabled. 
						# enable nonomatch
						setopt nonomatch
					fi

					sess_list=$(ls -d active.* 2>/dev/null)

					if [ $? -ne 0 ]; then
						if [ $nonomatch_was_enabled -eq 0 ]; then
							# nonomatch was originally not enabled.
							# So disable nonomatch
							unsetopt nonomatch
						fi

						echo "No live sessions found"
						return 3
					fi

					if [ $nonomatch_was_enabled -eq 0 ]; then
						# nonomatch was originally not enabled.
						# So disable nonomatch
						unsetopt nonomatch
					fi

					local at_least_one_live_session=0

					while IFS=$"\n"; read -r i; do
						cd "${ZSH_SESSION_PATH}/${i}"

						if [ -f ./session_in_use ]; then
							existing_session_lock_value=$(cat ./session_in_use)
							if [[ $existing_session_lock_value -ne 0 ]]; then
								echo $i | sed -e 's/active.//g'
								at_least_one_live_session=1
							fi
						else
							echo "$i is a Corrupted session -- Lock file not found."
						fi
					done <<< $sess_list

					if [[ $at_least_one_live_session -eq 0 ]]; then
						echo "No live sessions!"
					fi

					cd $curr_dir
					return 0
					;;
				all|A)
					cd $ZSH_SESSION_PATH

					echo "All Sessions (prefixed with state):"
					echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

					local nonomatch_was_enabled
					if utils:searchopt "nonomatch"; then
						nonomatch_was_enabled=1
					else
						nonomatch_was_enabled=0
						# nonomatch is not enabled. 
						# enable nonomatch
						setopt nonomatch
					fi

					sess_list=$(ls -d active.* 2>/dev/null)

					if [ $? -ne 0 ]; then
						sess_found=0
					fi

					while IFS=$"\n"; read -r i; do
						echo $i
					done <<< $sess_list

					sess_list=$(ls -d ended.* 2>/dev/null)

					if [ $? -ne 0 ] && [[ $sess_found -eq 0 ]]; then
						if [ $nonomatch_was_enabled -eq 0 ]; then
							# nonomatch was originally not enabled.
							# So disable nonomatch
							unsetopt nonomatch
						fi
						echo "No sessions found!"
						return 3
					fi

					if [ $nonomatch_was_enabled -eq 0 ]; then
						# nonomatch was originally not enabled.
						# So disable nonomatch
						unsetopt nonomatch
					fi

					while IFS=$"\n"; read -r i; do
						echo $i
					done <<< $sess_list

					cd $curr_dir
					return 0
					;;
				*)
					echo "Unknown list type supplied"
					sess:usage
					return 4
					;;
			esac
		fi
	fi

	# Handle creation, joining and ending of session
	local opt_cs # option create session
	local opt_js # option join session
	local opt_es # option end session
	local opt_ds # option delete session

	opt_cs=0
	opt_js=0
	opt_es=0
	opt_ds=0

	local addval # To add the results and reach a conclusion

	if utils:argument_exists_or_not '-c' $@ && utils:argument_exists_or_not '--create' $@; then
		# Both longform and shortform passed. 
		echo "Please use either -c or --create. Both cannot be used at once."
		sess:usage
		return 10
	elif utils:argument_exists_or_not '-c' $@ || utils:argument_exists_or_not '--create' $@; then
		# Either longform or shortform passed
		opt_cs=1

		if utils:argument_exists_or_not '-c' $@; then
			sess_name=$(utils:get_argument_value '-c' $@)
		elif utils:argument_exists_or_not '--create' $@; then
			sess_name=$(utils:get_argument_value '--create' $@)
		fi
	fi

	if utils:argument_exists_or_not '-j' $@ && utils:argument_exists_or_not '--join' $@; then
		echo "Please use either -j or --join. Both cannot be used at once."
		sess:usage
		return 11
	elif utils:argument_exists_or_not '-j' $@ || utils:argument_exists_or_not '--join' $@; then
		opt_js=1

		if utils:argument_exists_or_not '-j' $@; then
			sess_name=$(utils:get_argument_value '-j' $@)
		elif utils:argument_exists_or_not '--join' $@; then
			sess_name=$(utils:get_argument_value '--join' $@)
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
		opt_es=1

		if utils:argument_exists_or_not '-e' $@; then
			sess_name=$(utils:get_argument_value '-e' $@)
		elif utils:argument_exists_or_not '--end' $@; then
			sess_name=$(utils:get_argument_value '--end' $@)
		fi
	fi

	if utils:argument_exists_or_not '-D' $@ && utils:argument_exists_or_not '--delete' $@; then
		echo "Please use either -D or --delete. Both cannot be used at once."
		return 13
	elif utils:argument_exists_or_not '-D' $@ || utils:argument_exists_or_not '--delete' $@; then
		opt_ds=1

		if utils:argument_exists_or_not '-D' $@; then
			sess_name=$(utils:get_argument_value '-D' $@)
		elif utils:argument_exists_or_not '--delete' $@; then
			sess_name=$(utils:get_argument_value '--delete' $@)
		fi
	fi

	addval=$(( opt_cs + opt_js + opt_es + opt_ds ))

	# echo "addval= $addval"

	if [ $addval -gt 1 ]; then
		pr red "Malformed operations. Check usage:"
		echo ""
		sess:usage
		return 20
	elif [ $addval -eq 0 ]; then
		pr red "No operation supplied!"
		echo ""
		sess:usage
		return 20
	fi

	# Check if session name was empty (in case someone supplied the operation but not the session name)
	if [ -z "$sess_name" ]; then
    	pr red "Session name was not supplied. Check usage:"
    	sess:usage
    	return 21
  	fi

  	# Take the action!

	if [ $opt_cs -eq 1 ]; then
		# New session is to be created
		echo "Creating new session $sess_name"
		sess:create $sess_name
	fi

	if [ $opt_js -eq 1 ]; then
		# Existing session is to be joined
		sess:join $sess_name

		if [[ $sess_join_loop = "y" ]]; then
			# Let's loop 
			sess_join_limit=10
			n=1
			while [[ $n -le $sess_join_limit ]];do
				pr blue "--loop was supplied when joining the session. It will be rejoined $(( $sess_join_limit-$n )) times more."
				sess:join $sess_name
				let n=$n+1
			done
		fi
	fi

	if [ $opt_es -eq 1 ]; then
		# Session needs to be ended
		sess:end $sess_name
	fi

	if [ $opt_ds -eq 1 ]; then
		# Session needs to be deleted
		sess:delete $sess_name
	fi

	return 0
}

function sess:create() {
	# Check that the session already exists or not
	if [ -d "${ZSH_SESSION_PATH}/active.${1}" ]; then
		echo "An active session with that name already exists"
		echo "Please select a new name for the session"
		return 31
	fi

	if [ -d "${ZSH_SESSION_PATH}/ended.${1}" ]; then
		echo "An ended session with that name already exists."
		echo "Please select a new name for the session"
		return 32
	fi

	# All fine. create the session directory
	mkdir -p "${ZSH_SESSION_PATH}/active.${1}"
	# And the history file
	touch "${ZSH_SESSION_PATH}/active.${1}/zsh_history.txt"

	# Create lock file
	touch "${ZSH_SESSION_PATH}/active.${1}/session_in_use"

	# Put 0 in it
	echo "0" > "${ZSH_SESSION_PATH}/active.${1}/session_in_use"

	# Create the session initalization file
	touch "${ZSH_SESSION_PATH}/active.${1}/init.sh" 
	echo "#!/usr/bin/env zsh" >> "${ZSH_SESSION_PATH}/active.${1}/init.sh"

	# Insert the command to change the HISTFILE to the newly created history file.
	#   We do this because just setting the HISTFILE variable and launching the ZSH shell might not work!
	#   This is a known behavior with oh-my-zsh. 
	echo "fc -p ${ZSH_SESSION_PATH}/active.${1}/zsh_history.txt" >> "${ZSH_SESSION_PATH}/active.${1}/init.sh"

	# Put out the message
	pr blue "Init file created. If you want to customize the startup of this session, run:"
	pr blue white "sess --editinit"
	echo ""
	echo "Ensure that you have this line at the bottom of your .zshrc file:"
	echo "[[ -v ZSH_SESSION_INIT_FILE ]] && source \"\$ZSH_SESSION_INIT_FILE\""

	# and join the session
	sess:join $1
}

# This function allows you to edit a session's init.sh file
function sess:editinit() {
	if [[ ! -v ZSH_SESSION_NAME ]]; then
		pr red "Not inside an active session."
		echo "Please join a session first."
		return 40
	fi

	if [ ! -d "${ZSH_SESSION_PATH}/active.${ZSH_SESSION_NAME}" ]; then
		pr red "Active session's storage directory is not present!!!!!"
		pr red "!!! ABORTING !!!"
		return 39
	fi

	$EDITOR "${ZSH_SESSION_PATH}/active.${ZSH_SESSION_NAME}/init.sh"
}

function sess:join() {
	# If we are already in a session, we should get into another session
	if [[ -v ZSH_SESSION_NAME ]]; then
		echo "Cannot join another session while one is active!"
		echo "Already in session \"$ZSH_SESSION_NAME\".";
		return 40
	fi

	if [ -d "${ZSH_SESSION_PATH}/ended.${1}" ]; then
		echo "An ended session with that name already exists."
		echo "Cannot join an ended session"
		return 33
	fi

	# Check that the session exists and is active.
	if [ ! -d "${ZSH_SESSION_PATH}/active.${1}" ]; then
		echo "No session with that name is active."
		echo "Please create a session with that name first."
		return 34
	elif [ ! -f "${ZSH_SESSION_PATH}/active.${1}/zsh_history.txt" ]; then
		echo "Session exists but history file was not found in path."
		echo "It appears that the session was corrupted."
		echo "Please create a new session with a different name."
		return 35
	fi

	# Local session_id & final value
	local session_id
	local final_value
	session_id=$(( $(date +%s) % 1580000000 ))

	# Value in the lock file
	local existing_session_lock_value
	existing_session_lock_value=$(cat "${ZSH_SESSION_PATH}/active.${1}/session_in_use")

	final_value=$(( session_id + existing_session_lock_value ))

	echo "$final_value" > "${ZSH_SESSION_PATH}/active.${1}/session_in_use"

	echo "Joining session $1"

	# Prevent error message
	touch "${ZSH_SESSION_PATH}/active.${1}/init.sh"

	# All fine. Join session.
	# ZSH_SESSION_NAME=$1 HISTFILE="${ZSH_SESSION_PATH}/active.${1}/zsh_history.txt" ZSH_SESSION_INIT_FILE="${ZSH_SESSION_PATH}/active.${1}/init.sh" zsh --hist-ignore-space 
	ZSH_SESSION_NAME=$1 ZSH_SESSION_INIT_FILE="${ZSH_SESSION_PATH}/active.${1}/init.sh" zsh --hist-ignore-space

	echo "Exited from session $1"

	# Session has ended. Reduce the value in the lock file
	existing_session_lock_value=$(cat "${ZSH_SESSION_PATH}/active.${1}/session_in_use")
	final_value=$(( existing_session_lock_value - session_id ))
	echo "$final_value" > "${ZSH_SESSION_PATH}/active.${1}/session_in_use"
}

function sess:end() {
	if [ -d "${ZSH_SESSION_PATH}/ended.${1}" ]; then
		echo "An ended session with that name already exists."
		echo "Cannot end an already ended session"
		return 36
	fi

	if [ ! -d "${ZSH_SESSION_PATH}/active.${1}" ]; then
		echo "No session with that name is active."
		echo "Cannot end a non-existent session"
		return 37
	elif [ ! -f "${ZSH_SESSION_PATH}/active.${1}/zsh_history.txt" ]; then
		echo "Session exists but history file was not found in path."
		echo "It appears that the session was corrupted."
		echo "We will NOT END the session to allow debugging and correction."
		return 38
	fi

	# Check the lock file value and if it is 0, end the session
	local existing_session_lock_value
	existing_session_lock_value=$(cat "${ZSH_SESSION_PATH}/active.${1}/session_in_use")

	if [ $existing_session_lock_value -gt 0 ]; then
		echo "Cannot end a session currently in use."
		echo "It appears that the session is in use in another terminal."
		echo "Please exit all shells using the session and retry."
		echo "Run 'echo \$ZSH_SESSION_NAME' in a shell to check session name (if it's using session facility)"
		return 39
	else
		# We should end the session
		mv "${ZSH_SESSION_PATH}/active.${1}" "${ZSH_SESSION_PATH}/ended.${1}"
		echo "Session $1 ended!"
	fi 
}

# 
function sess:delete() {
	if [ -d "${ZSH_SESSION_PATH}/active.${1}" ]; then
		pr red "Cannot delete an active session!"
		echo "Please end the session and try again."
		return 46
	fi

	if [ ! -d "${ZSH_SESSION_PATH}/ended.${1}" ]; then
		pr red "No such session. Cannot delete a non-existent session!"
		return 47
	fi

	pr blue "Are you sure?"
	pr blue "-------------"

	read -k1 "choice?Are you sure you want to delete session '${1}'? [y/n]"
	if [[ $choice = "y" || $choice = "Y" ]]; then
		echo ""
		pr red "Deleting session"
		rm -r "${ZSH_SESSION_PATH}/ended.${1}"
		pr green "...done"
	else
		pr blue "You opted for not deleting the session."
		pr blue "!!! Aborting !!!"
		return 48
	fi

	return 0
}

function sess:usage() {
	echo "Usage: You can use sess in one of the following ways:"
	echo ""
	echo "sess MGMT_OPERATION sess_name"
	echo "sess -l LIST_TYPE"
	echo "sess --editinit"
	echo ""
	echo "MGMT_OPERATION can be one of:"
	echo "  -c (or --create)  Creates a new session with sess_name as its name."
	echo "                    Created session will be joined immediately"
	echo "  -j (or --join)    Joins the session with sess_name. The session must already exist."
	echo "                    Adding '--loop' after the session name will rejoin the session"
	echo "                      for upto 10 quits."
	echo "  -e (or --end)     Ends the session with sess_name."
	echo "  -D (or --delete)  Deletes an ended session with sess_name from disk."
	echo "  --editinit        Opens nano to let you edit the sess_name's init.sh file"
	echo ""
	echo "LIST_TYPE can be one of:"
	echo "  a (or active)     For listing active sessions"
	echo "  l (or live)       For listing live sessions"
	echo "                    Live sessions are active sessions running in a terminal right now"
	echo "  e (or ended)      For listing ended sessions"
	echo "  A (or all)        For listing all sessions"
	echo ""
	echo "The --editinit option opens nano to let you edit the active session's init.sh file"
	echo "  This option requires that you are already inside the session whose init file you want to edit."
}

function sess:startup_check() {
	if [ $# -lt 1 ]; then
		echo "You are not supposed to call this command manually"
		return 100
	fi

	# Check if the variable is set
	if [[ ! -v ZSH_SESSION_PATH ]]; then
		echo "ZSH_SESSION_PATH is not set."
		echo "Sessions needs a directory to store sessions data."
		echo "Create the directory and set ZSH_SESSION_PATH to that value."
		echo ""
		echo "For example, you might run these commands to create the directory:"
		echo ""
		echo "mkdir -p \$HOME/bin/zsh_sessions"
		echo ""
		echo "Then you might want to add it to the exports file. e.g. by running the commands below:"
		echo "touch \$ZEXT_INSTALL_DIR/installed/scripts/_exports.zsh;"
		echo "echo \"ZSH_SESSION_PATH=\$HOME/bin/zsh_sessions\" > \$ZEXT_INSTALL_DIR/installed/scripts/_exports.zsh;"
		return 1
	fi

	# Check that the directory exists
	if [ -e "$ZSH_SESSION_PATH" ]; then
		# Path exists
		# Check if it is a file.
		if [ -f "$ZSH_SESSION_PATH" ]; then
			# It is a file. 
			echo "ZSH_SESSION_PATH points to a file."
			echo "Please make sure that it points to a directory."
			return 2
		fi

		# Check that it is not a symbolic link 
		if [ -d "$ZSH_SESSION_PATH" ]; then
			if [ -L "$ZSH_SESSION_PATH" ]; then
				echo "ZSH_SESSION_PATH is a symlink to a directory."
				echo "Please make sure that it points to a directory, not to a symlink."
				return 2
			fi
		else
			echo "ZSH_SESSION_PATH points to an address which is not a directory."
			echo "Please make sure that it points to a directory."
			return 4
		fi
	else 
		echo "ZSH_SESSION_PATH points to a non-existent location."
		echo "Sessions needs a directory to store sessions data."
		echo "Create the directory and set ZSH_SESSION_PATH to that value."

		echo "Run this to create the directory:"
		echo ""
		echo "mkdir -p $ZSH_SESSION_PATH"

		return 5
	fi

	return 0
}

function sess_help() {
	sess:usage
}

function sess_oneliner() {
	echo "sess: Session management with ZSH!!"
}
