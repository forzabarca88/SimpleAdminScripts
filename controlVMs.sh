#!/bin/bash
#Runs commands on multiple machines
#Requires private key authentication and NOPASSWD in sudo
#Usage - ./controlVMs.sh <update | shutdown>

hosts=( "jdc-centos-network" "jdc-centos-app" "jdc-centos-app2" )

operation=$1

for i in ${hosts[@]}
do
	if ping -c 1 $i &> /dev/null
	then
		if [ $operation = "shutdown" ]
		then
			ssh $i 'systemctl poweroff'
			echo Shutdown command sent to $i, return code - $?

		elif [ $operation = "update" ]
		then
			ssh $i 'correctpkg=$(whereis apt) && [ "$correctpkg" = "apt:" ] && sudo yum update -y' &
			ssh $i 'correctpkg=$(whereis yum) && [ "$correctpkg" = "yum:" ] && sudo apt-get update -y && sudo apt-get upgrade -y' &
			echo Update command sent to $i, return code - $?
		else
			echo Invalid operation specified.
		fi
	else
		echo $i currently not reachable, skipping....
	fi
done

wait

echo Remote machines processed.

if [ $operation = "shutdown" ]
then
	echo Shutting down local machine in 5 seconds.
	sleep 5s
	systemctl poweroff
elif [ $operation = "update" ]
then
	echo Updating local machine.....
	correctpkg=$(whereis apt) && [ "$correctpkg" = "apt:" ] && sudo yum update -y
	correctpkg=$(whereis yum) && [ "$correctpkg" = "yum:" ] && sudo apt-get update -y && sudo apt-get upgrade -y
else
	echo Invalid operation specified.
fi
