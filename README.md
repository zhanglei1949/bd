# Multi-version Hadoop Deployment and Manager

Utilize this Ansible-playbook, I implement a muli-version Hadoop deployment script, which support deploying multiple version Hadoop on same cluster, and allowing switching among different versions. The key implementation is in ```deploy.sh```

## Usage 
This script is built over [bd playbook](https://github.com/Intel-bigdata/bd).
### Deploy
```./deploy.sh -i```

This command will install the hadoop(and other packages) specified in ./vars/resources.yml. If a previous hadoop is installed, it will be moved to ``/hadoop-backup/``, and it will renamed with a unique name (hadoop+version+date+0/1/2...).
### Roll Back

```./deploy.sh -r [name of previous installed hadoop]```

Running this script, the current hadoop in use will be backed up, and the previous install hadoop will be recovered to ``/hadoop``
# About

This is an Ansible Playbook to deploy data lab environments with any number of
tools commonly used by by data driven organizations. The purpose of the playbook
is to accelerate the deployment of data labs, enforcing consistency across labs,
for functional and performance testing.

Post deploy, the following software will be available inside the data lab:

* Hadoop 2.7.3
* Spark 2.1.1
* Hive 2.2.1
* Presto 0.177

# Dependencies

This playbook depends on the "oracle-java" playbook, you will need to install
it from Ansible Galaxy. You can do this by running this command, assuming you
have Ansible installed.

```sudo ansible-galaxy install ansiblebit.oracle-java```

# Provision Data Lab on AWS EC2

The easiest way to experiment with this playbook and familiarize yourself with
the data lab it creates is to leverage Amazon EC2. Several python packages are
necessary for this approach, we recommend they be installed with pip:

```sudo pip install --upgrade awscli boto3```

In order to be able to access the data lab you will need to provide some
information in the form of variables. These variables are defined by editing
the ``vars/ec2.yml`` file, notably:

   - ``my_ip`` : Add public ip address of your workstation
   - ``ec2_keypair`` : Add your EC2 keypair name

You will also need to export your **AWS_ACCESS_KEY** and **AWS_SECRET_KEY** as
environment variables:

```
export AWS_ACCESS_KEY='Your_AWS_Access_Key_Here'
export AWS_SECRET_KEY='Your_AWS_Secret_Key_Here'
```

With the ansible and environmental variables set, you can instruct Ansible to
boot your data lab by executing the ``boot.yml`` play:

```ansible-playbook -i hosts boot.yml```

If you want to avoid having to accept host keys, you can use an environmental
variable to tell Ansible not to check host SSH keys:

```export ANSIBLE_HOST_KEY_CHECKING=False```

After the data lab is booted, verify ansible can reach all hosts:

```ansible -i ec2.py -u ec2-user -m ping all```

Once you have verified that all hosts are reachable, you can execute the site
play:

```ansible-playbook -i ec2.py site.yml```

# Provision Data Lab on Bare Metal

If you decide to deploy to bare metal servers, the current assumption is that
they are provisioned running Red Hat Enterprise Linux. Distributions like
CentOS may work, but haven't been tested.

When you deploy to bare metal, you need to specify which group a particular
node will assume in an Ansible inventory file. There are two main host groups
for this playbook, with an example inventory named ``hosts`` in the root of the
playbook repository.

You should change the deploy_method variable in the ``group_vars/all`` file to
``bare``.

You can choose two different mode in this deployment, with s3a support or without s3a support. You should first add your hosts to the inventory file, you can run one site play :

```ansible-playbook -i hosts site-s3a.yml```

for deployment with s3a support, and run the other site play:

```ansible-playbook -i hosts site-without-s3a.yml```

for deployment without s3a support.

When it finishes, you should have a complete data lab ready to go!

# Deployed Environment

* master 
* core

The "master" host runs cluster services, and serve as a client bastion to launch
benchmarks from. You should only have one "master" host in your cluster.

* yarn resource manager
* yarn history server
* hdfs namenode
* hive metastore
* presto coordinator

The "core" hosts do the heavy lifting, running map reduce or spark tasks on
yarn, or processing queries on presto workers.

* yarn node manager
* hdfs datanode
* kafka broker
* presto worker

# FAQ
* If you have problems downloading packages, you can download them manually and place them at a direction which you need to specify as ```tarball_prefix``` in ```./var/resources.yml```

* Please specify ```hive metastore warehouse``` and ```hive scratch direction``` in ```./group_vars/all``` 

* If you encounter build failure with /hadoop-home/hive-testbench/tpcds-build.sh and the error is due to connection time out to repo.maven.apache.org, please add one proxy server which can access that url in ./maven/conf/settings.conf, proxy section.

* Hive-testbench
Please first run ```tpcds-build.sh``` , then ```tpcds-setup.sh``` to generate data, and ```tpcds-run.sh``` for benchmarking. Please check the details in ```/hadoop-home/hive-testbench/README.md```.

