#!/bin/bash
# this is meant to be run from within the root git directory

# grep processes with `thin` in them, list their PIDs, kill them softly
ps ax | fgrep thin | awk '{print $1}' | tr '\n' ' ' | xargs kill -15

# just in case... (kill -2)
sleep 1
ps ax | fgrep thin | awk '{print $1}' | tr '\n' ' ' | xargs kill -2

# just in case... (kill -9)
sleep 1
ps ax | fgrep thin | awk '{print $1}' | tr '\n' ' ' | xargs kill -9

thin -R config.ru -p 7000 -s 2 start

echo 'Done restarting.'
