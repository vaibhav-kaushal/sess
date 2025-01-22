#!/usr/bin/env zsh

if [ -d "${ZSHY_SESS_DATA_PATH}/ended.${1}" ]; then
  echo "An ended session with that name already exists."
  echo "Cannot end an already ended session"
  return 36
fi

if [ ! -d "${ZSHY_SESS_DATA_PATH}/active.${1}" ]; then
  echo "No session with that name is active."
  echo "Cannot end a non-existent session"
  return 37
elif [ ! -f "${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" ]; then
  echo "Session exists but history file was not found in path."
  echo "It appears that the session was corrupted." 
  echo "We will NOT END the session to allow debugging and correction."
  return 38
fi

# Check the lock file value and if it is 0, end the session
__existing_session_lock_value
__existing_session_lock_value=$(cat "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use")

if [ $__existing_session_lock_value -gt 0 ]; then
  echo "Cannot end a session currently in use."
  echo "It appears that the session is in use in another terminal."
  echo "Please exit all shells using the session and retry."
  echo "Run 'echo \$ZSH_SESSION_NAME' in a shell to check session name (if it's using session facility)"
  return 39
else
  # We should end the session
  mv "${ZSHY_SESS_DATA_PATH}/active.${1}" "${ZSHY_SESS_DATA_PATH}/ended.${1}"
  echo "Session $1 ended!"
fi

unset __existing_session_lock_value