#!/bin/bash
#Runs commands on multiple machines
#Requires private key authentication and NOPASSWD in sudo
#Usage - ./controlVMs.sh < update | shutdown | -c "command" >

hosts=( "jdc-centos-network" "jdc-centos-app" "jdc-centos-app2" )

operation=$1

for i in ${hosts[@]}
do
	if ping -c 1 $i &> /dev/null
	then
		if [ $operation = "shutdown" ]
		then
			ssh $i 'sudo systemctl poweroff'
			echo "Shutdown command sent to $i."

		elif [ $operation = "update" ]
		then
			ssh $i 'correctpkg=$(whereis apt) && [ "$correctpkg" = "apt:" ] && sudo yum update -y' &
			ssh $i 'correctpkg=$(whereis yum) && [ "$correctpkg" = "yum:" ] && sudo apt-get update -y && sudo apt-get upgrade -y' &
			echo "Update command sent to $i."
		elif [ $operation = "-c" ]
		then
			comm=$2
			echo "Running command - $2"
			ssh $i '$comm' &
		else
			echo "Invalid operation specified."
		fi
	else
		echo "$i currently not reachable, skipping...."
	fi
done

wait

echo "Remote machines processed."

if [ $operation = "shutdown" ]
then
	echo "Press any key to shutdown the local machine, or press CTRL-C to exit script."
	read -s -n 1 && sudo systemctl poweroff
elif [ $operation = "update" ]
then
	echo "Updating local machine....."
	correctpkg=$(whereis apt) && [ "$correctpkg" = "apt:" ] && sudo yum update -y
	correctpkg=$(whereis yum) && [ "$correctpkg" = "yum:" ] && sudo apt-get update -y && sudo apt-get upgrade -y
else
	echo "Invalid operation specified."
fi
