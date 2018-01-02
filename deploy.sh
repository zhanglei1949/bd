#!/bin/bash
# No need to umount disk and remount, just remove the data (hdfs cluster)

backup_dir=/hadoop-backup/
headnode=client1
servers="client1 client2"

shutdown_hadoop()
{
	# first check whether hadoop is running on each server, and shut them down
	echo "***********************************************************************"
	echo  first check whether hadoop is running on each server, and shut them down
	echo stoping hadoop processes on head node$server
	for server in $servers;
	do
		#ssh $server jps
		echo shuting down hadoop on $server
		ssh $server /hadoop/sbin/stop-all.sh
	done
	echo ""
# get the date
}
umount_disk()
{
	# Secondly umount all using  disks
	echo "***********************************************************************"
	echo Umount all using  disks
 
	for server in $servers;
	do
		echo "umounting disks on"$server
		disks=`ssh $server df | grep hadoop |awk '{print $1}'`
		umount $disks
		echo $disks
	done
}
# Thirdly rename the hadoop directory to a unique name
move_hadoop_dir()
{
	echo "***********************************************************************"
	echo Rename the hadoop directory to a unique name
	echo "first check whether the backup directory exists"
	for server in $servers;
	do
		if ssh $server test -d $backup_dir;
		then
			echo "Back up diretory exists on $server"
		else
			echo "creating directory on $server"
			ssh $server mkdir -p $backup_dir
		fi
	done

	if [ -d "/hadoop" ];
	then
		hadoop_version=`hadoop version | grep Hadoop | awk '{print $2}'`
		echo hadoop version is :$hadoop_version
		back_up_dir=${backup_dir}"hadoop"${hadoop_version}"-"`date +%Y-%m-%d`
		echo can we rename the directory to $back_up_dir ?
		if [ -d $back_up_dir ];
		then
			echo No, we can\'t
			i=0
			while [ -d ${back_up_dir}"-"${i} ]
			do
				echo ${back_up_dir}"-"${i}
				i=$[i+1]
			done
			back_up_dir=${back_up_dir}"-"${i}
		else
			echo "yes we can"
		fi
		echo Finally using this one: $back_up_dir
		echo 
		for server in $servers;
		do
			echo "on $server, mv /hadoop to $back_up_dir"
			echo "delete the data directories "
			ssh $server rm -rf /hadoop/hdfs
			echo "move /hadoop to "${back_up_dir}
			ssh $server mv /hadoop $back_up_dir 
			echo 
		done

	else
		echo "hadoop not installed"
	fi
}
# Forthly, run ansible-playbook deployment
deploy()
{
	echo "***********************************************************************"
	echo "deploy hadoop using ansible playbook"
	cmd="ansible-playbook -i hosts"
	#if [ ${with_s3a} == 1 ];
	#then
	#	echo "with s3a support, using file site-s3a"
	#
	#	cmd=$cmd" site-s3a.yaml "
	#else
		echo "without s3a"
		cmd=$cmd" site-without-s3a.yml"
	#fi
	echo ""
	${cmd}
}
#cmd=$cmd" --extra-vars '{\"install_java\":\"$install_java\",\"install_common\":\"$install_common\",\"install_hadoop_common\":\"$install_hadoop_common\",\"install_hive\":\"$install_hive\",\"install_spark\":\"$install_spark\",\"install_maven\":\"$install_maven\",\"install_hive_testbench\":\"$install_hive_testbench\",\"install_presto\":\"$install_presto\"}'"
#echo $cmd

install()
{
	shutdown_hadoop
	move_hadoop_dir
	#umount_disk
	deploy
}
rollback()
{
	#this function accept one parameter as the candidate of rollback version of hadoop
	shutdown_hadoop
	move_hadoop_dir
	echo "roll back to $1"
	echo "this directory $backup_dir$1"
	mv $backup_dir$1 /hadoop
	
}
usage()
{
	echo "This scripts utilized ansible-playbook for hadoop deployment and maintainess among different versions"
	echo "-h	helps"
	echo "-i	install new hadoop which is specified in ./vars/resources"
	echo "-r [name]	roll back to previous intalled version, please specify the name of directory"
}
#parsing options
while getopts "ir:" opt;
do
	case $opt in 
	i)
		echo "installing new version"
		install
		exit 1
		;;
	r)
		echo "roll back to $OPTARG"
		rollback $OPTARG
		exit 1
		;;
	h)
		usage
		exit 1
		;;
	\?)
		echo "invalid optiion"
		usage
		exit 1
		;;
	esac
done

