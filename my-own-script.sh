#!/bin/bash

#Password creator script

if [[ "${UID}" -ne 0 ]]
then
  echo  'In order to use this application you need to be a root user or use sudo'
  echo "Arguments:${#}"
  echo "Status: 1"
  exit 1
else
  read -p 'Welcome to the Password Creator App, please type the letters you want to use to create your own password: ' LETTERS
  echo ${LETTERS} | sha256sum | head -c20
  echo
  echo "New Password created, please save it in a safe place and never share it!"
  echo
  # This captures the number of arguments passed to the script
  echo "Arguments: ${#}"

  # this captures the return status of the executed the script
  echo "Status: ${?}"

  #this captures all the arguments passed to the script
  echo "All arguments passed from the user: ${@}"

  #this captures the last command executed
  echo "Last command executed: ${0}"
  exit 0
fi
