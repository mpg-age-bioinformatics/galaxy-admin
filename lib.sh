#!/bin/bash

quit () { echo "error: $@" ; exit 65 ; }

update () {
  local file
  local target
  file="$1"
  target="$($sudo readlink -f $2)"
  echo "* target $target"
  if [[ -f $target ]]
  then
    d=$(diff $target $file)
  else
    d=$(diff <(echo -n "") $file)
  fi
  echo -n "  diff ... "
  if [[ -n $d ]]
  then
    echo -n "show? [y/n] "
    read -n 1 key
    echo -n " ... "
    if [[ $key = y ]]
    then
      echo
      echo
      if [[ -f $target ]]
      then
        diff $target $file | sed 's/^/\ \ \ \ /'
      else
        diff <(echo -n "") $file | sed 's/^/\ \ \ \ /'
      fi
      echo
      echo -n "       ... "
    fi
    echo -n "update? [y/n] "
    read -n 1 key
    echo
    if [[ $key = y ]]
    then
      mkdir -p $(dirname $target) || exit
      install -m 664 -g $GA_GROUP $file $target || exit
    fi
  else
    echo "none"
  fi
}


