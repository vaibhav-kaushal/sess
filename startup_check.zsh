#!/usr/bin/env zsh

if [ $# -lt 1 ]; then
  echo "You are not supposed to call this command manually"
  return 100
fi

# Check if the variable is set
if [[ ! -v ZSH_SESSION_PATH ]]; then
  echo "ZSH_SESSION_PATH is not set."
  echo "Sessions needs a directory to store sessions data."
  echo "Create the directory and set ZSH_SESSION_PATH to that value."
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
