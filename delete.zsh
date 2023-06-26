#!/usr/bin/env zsh

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

read -k1 "choice?Are you sure you want to delete session '${1}'? [y/n] "
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
