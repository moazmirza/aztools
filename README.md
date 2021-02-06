# aztools
The tool enables logical execution of azacsnap on the active master node, and logical execution of azcopy on the stand-by node. 
To enhance the execution experience of azacsnap and azopy for the purpose of ANF snapshots and offloading of those snapshots on HANA scale-out nodes. This is a linear citizen-style bash script, feel free to fork and enhance for your purpose.

Follow the following process to handle the execution of azacsnap and azcopy through aztools.

•	Create a shell script on the central management server, called “aztools.sh”, pronounced easy tools – pun intended. You can use azacsnap user to execute this.
•	Update the crontab to execute this bash script instead of the azacsnap.
•	Remove the crontab execution for azcopy on the stand-by node.
•	Create a password less ssh connection configuration between the management and the HANA nodes by sharing the ssh keys. The result: azacsnap should be able to ssh into any HANA node using the sidadm user without having to enter the password. You can also use a dedicate azcopy user on HANA nodes if you’d like. 
•	Now let’s add some logic in this new shell script:
o	Determine if the HANA nodes have key HANA processes running. You are essentially checking if the node is up and carrying out “a” role.
o	Determine the current name server node and the stand-by node from the nameserver configuration.
o	Provide execution choices of running azacsnap or azcopy by passing a selection parameter at the execution time.
o	In addition, provide a choice of choosing the volume to execute the tool against by passing a parameter at the execution time.
o	Update the azacsnap config file with the current master node.
o	Declare variables to store azacsnap and azcopy command settings.
o	Update the azacsnap command to execute on the volume of choice.
o	Update azcopy command to offload the volume of choice.
o	Now, the execution of this new shell script for a three-node system would look like:
./aztools.sh <sidadm> <host1> <host2> <host3> <azacsnap|azcopy> <data|logbackup|shared>

All the logic stated above is included in the aztools.sh file attached.

Note: This is not an official Microsoft solution, merely a student jotting his thoughts down - use it at your own risk.

Enjoy!
