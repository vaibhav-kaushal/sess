#!/usr/bin/env zsh

if [[ ! -v ZSH_SESSION_NAME ]]; then
  pr red "Not inside an active session."
  echo "Please join a session first."
  return 40
fi

if [ ! -d "${ZSHY_SESS_DATA_PATH}/active.${ZSH_SESSION_NAME}" ]; then
  pr red "Active session's storage directory is not present!!!!!"
  pr red "!!! ABORTING !!!"
  return 39
fi

$EDITOR "${ZSHY_SESS_DATA_PATH}/active.${ZSH_SESSION_NAME}/init.sh"
