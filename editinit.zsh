#!/usr/bin/env zsh

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
