#!/bin/sh
echo "Hello"
/usr/sbin/sshd -De
tail -f /dev/null