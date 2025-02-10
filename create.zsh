#!/usr/bin/env zsh

# Check that the session already exists or not
if [ -d "${ZSHY_SESS_DATA_PATH}/active.${1}" ]; then
  echo "An active session with that name already exists"
  echo "Please select a new name for the session"
  return 31
fi

if [ -d "${ZSHY_SESS_DATA_PATH}/ended.${1}" ]; then
  echo "An ended session with that name already exists."
  echo "Please select a new name for the session"
  return 32
fi

# All fine. create the session directory
mkdir -p "${ZSHY_SESS_DATA_PATH}/active.${1}"
# And the history file
touch "${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt"

# Create lock file
touch "${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"

# Put 0 in it
echo "0" >"${ZSHY_SESS_DATA_PATH}/active.${1}/session_in_use"

# Create the session initalization file
touch "${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"
echo "#!/usr/bin/env zsh" >>"${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"

# Insert the command to change the HISTFILE to the newly created history file.
#   We do this because just setting the HISTFILE variable and launching the ZSH shell might not work!
#   This is a known behavior with oh-my-zsh.
echo "fc -p ${ZSHY_SESS_DATA_PATH}/active.${1}/zsh_history.txt" >>"${ZSHY_SESS_DATA_PATH}/active.${1}/init.sh"

# Put out the message
clpr blue "Init file created. If you want to customize the startup of this session, run:"
clpr blue white "sess --editinit"
echo ""
echo "Ensure that you have this line at the bottom of your .zshrc file:"
echo "[[ -v ZSH_SESSION_INIT_FILE ]] && source \"\$ZSH_SESSION_INIT_FILE\""

# and join the session
source ${0:A:h}/join.zsh $1


