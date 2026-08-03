#!/bin/zsh

cd /mnt/c/Users/barth/Desktop

tasklist.exe | grep -aiP "$*" | read HIT
tasklist.exe | grep -aiP "$*" | awk '{ print $2 }' | read -A pid

# hit=( "${(f)HIT[@]}" )

select P in ${(f)hit[@]};
do
	taskkill.exe /PID "${pid[$P]}"
done
