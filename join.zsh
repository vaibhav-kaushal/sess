#!/usr/bin/env zsh

# If we are already in a session, we should get into another session
if [[ -v ZSH_SESSION_NAME ]]; then
  echo "Cannot join another session while one is active!"
  echo "Already in session \"$ZSH_SESSION_NAME\"."
  return 40
fi

if [ -d "${ZSHY_SESS_DATA_PATH}/ended.${1}" ]; then
  echo "An ended session with that name already exists."
  echo "Cannot join an ended session"
  return 33
fi

# Check that the session exists and is active.
if [ ! -d "${ZSHY_SESS_DATA_PATH}/active.${1}" ]; then
  echo "No session with that name is active."
  echo "Please create a session with that name first."
  return 34
elif [ ! -f "${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" ]; then
  echo "Session exists but history file was not found in path."
  echo "It appears that the session was corrupted."
  echo "Please create a new session with a different name."
  return 35
fi

__session_id=$(($(date +%s) % 1580000000))

# Value in the lock file
__existing_session_lock_value=$(cat "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use")

__final_value=$((__session_id + __existing_session_lock_value))

echo "$__final_value" >"${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"

echo "Joining session $1"

# Prevent error message
touch "${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"

# All fine. Join session.
# ZSH_SESSION_NAME=$1 HISTFILE="${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" ZSH_SESSION_INIT_FILE="${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh" zsh --hist-ignore-space
ZSH_SESSION_NAME=$1 ZSH_SESSION_INIT_FILE="${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh" zsh --hist-ignore-space

echo "Exited from session $1"

# Session has ended. Reduce the value in the lock file
__existing_session_lock_value=$(cat "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use")
__final_value=$((__existing_session_lock_value - __session_id))
echo "$__final_value" >"${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"

unset __session_id
unset __final_value
unset __existing_session_lock_value
