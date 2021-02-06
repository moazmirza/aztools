#!/bin/bash
azacsnapDataConfig="HN1Config.json"
azacsnapLogBConfig="HN1Config.json"
azacsnapSharedConfig="HN1Shared.json"
# Prefixes for ANF and HANA snapshots
dataPrefix="HN1DataHrly"
logBPrefix="HN1LogBk20min"
sharedPrefix="HN1SharedDly"
# Retentions for snapshots
dataRetent=12
logBRetent=48
sharedRetent=2
#Variables for azcopy
azcopyLoc="/usr/sap/HN1/home/azcopy/"
data1src="/hana/data/HN1/mnt00001/.snapshot"
data2src="/hana/data/HN1/mnt00002/.snapshot"
sharedsrc="/hana/shared/.snapshot"
logbackupsrc="/backup/log"
saBlobUrl="https://immutbackups.blob.core.windows.net"
data1BlobLoc="hn1immutable/mnt00001"
data2BlobLoc="hn1immutable/mnt00002"
sharedBlobLoc="hn1immutable/shared"
logBackupBlobLoc="hn1replication/logbackup"
echo "Checking to see if HANA name server is running on the first node: "$2
ps1=$(ssh $1@$2 -- ps -ef | egrep 'hdbnameserver|hdbindexserver|hdbxsengine' | grep hn1adm | awk '{print $8}')
if [[ " ${ps1[@]} " =~ "hdbnameserver" ]]
then
echo "Name server is running on the first node, let's read nodes' current roles..."
masterNode=$(ssh hn1adm@hana1 -- cat /usr/sap/HN1/SYS/global/hdb/custom/config/nameserver.ini | grep 'active_master =' | awk '{print $3}' | cut -d : -f 1)
standByNode=$(ssh hn1adm@hana1 -- cat /usr/sap/HN1/SYS/global/hdb/custom/config/nameserver.ini | grep 'standby =' | awk '{print $3}')
echo "Master  Node: "$masterNode
echo "StandBy Node: "$standByNode
else
 echo "Checking to see if HANA name server is running on the second node: "$3
 ps2=$(ssh $1@$3 -- ps -ef | egrep 'hdbnameserver|hdbindexserver|hdbxsengine' | grep hn1adm | awk '{print $8}')
 if [[ " ${ps1[@]} " =~ "hdbnameserver" ]]
 then
  echo "Name server is running on the second node, let's read nodes' current roles..."
  masterNode=$(ssh hn1adm@hana1 -- cat /usr/sap/HN1/SYS/global/hdb/custom/config/nameserver.ini | grep 'active_master =' | awk '{print $3}' | cut -d : -f 1)
  standByNode=$(ssh hn1adm@hana1 -- cat /usr/sap/HN1/SYS/global/hdb/custom/config/nameserver.ini | grep 'standby =' | awk '{print $3}')
  echo "Master  Node: "$masterNode
  echo "StandBy Node: "$standByNode
 else
  echo "Couldn't find name server running on "$2 "node or on the "$3 "node. Check the health of your HANA system first."
  echo "Ending further execution of aztools."
 fi
fi
echo "Executing the selected tool: "$5 "for the selected volume: "$6 "..."
if [[ $5 = "azcopy" ]]
then
 if [[ $6 = "data" ]] 
 then
  echo "Starting offloading the Data Snapshots in /hana/data/<SID>mnt0000x to the storage account using the stand-by node "$standByNode"."
  ssh $1@$standByNode 'cd $azcopyLoc; ./azcopy login --identity; ./azcopy sync $data1src $saBlobUrl/$data1BlobLoc --recursive=true; ./azcopy sync $data2src $saBlobUrl/$data2BlobLoc --recursive=true' 
  echo "aztools>azcopy offloading complete"
 elif [[ $6 = "logbackup" ]]
 then
  echo "Starting offloading the Log Backups in the /backup to the storage account using the stand-by node "$standByNode"." 
  ssh $1@$standByNode 'cd $azcopyLoc; ./azcopy login --identity; ./azcopy sync $logbackupsrc $saBlobUrl/$logBackupBlobLoc --recursive=true'
  echo "aztools>azcopy offloading complete"
 elif [[ $6 = "shared" ]]
 then
  echo "Starting offloading the /hana/shared snapshots to the storage account using the stand-by node "$standByNode"."
  ssh $1@$standByNode 'cd $azcopyLoc; ./azcopy login --identity; ./azcopy sync $sharedsrc $saBlobUrl/$sharedBlobLoc --recursive=true' 
  echo "aztools>azcopy offloading complete"
 else
  echo "Please select the correct choice for aztools execution. $1 is <sidadm>, $2 is node1, $3 is node2, $4 is node3, $5 is azcopy|azacsnap, $6 is data|logbackup|shared"
 fi
elif [[ $5 = "azacsnap" ]]
then
  if [[ $6 = "data" ]]
 then
  echo "Starting application consistent ANF snapshots using azacsnap on /hana/data/<SID>mnt0000x using the master node "$masterNode"."
  sed -i 's/^\(\s*"serverAddress"\s*:\s*\).*$/\1"'$masterNode'",/' /home/azacsnap/bin/$azacsnapDataConfig
  ./azacsnap --configfile $azacsnapDataConfig -c backup --volume data --prefix $dataPrefix --retention $dataRetent --trim
  echo "aztools>azacsnap complete"
 elif [[ $6 = "logbackup" ]]
 then
  echo "Starting ANF snapshot using azacsnap on logbackup volume using the master node "$masterNode"."
  sed -i 's/^\(\s*"serverAddress"\s*:\s*\).*$/\1"'$masterNode'",/' /home/azacsnap/bin/$azacsnapLogBConfig
  ./azacsnap --configfile $azacsnapLogBConfig -c backup --volume other --prefix $logBPrefix --retention $logBRetent
  echo "aztools>azacsnap complete"
 elif [[ $6 = "shared" ]]
 then
  echo "Starting ANF snapshots using azacsnap on /hana/shared volume using the master node "$masterNode"."
  sed -i 's/^\(\s*"serverAddress"\s*:\s*\).*$/\1"'$masterNode'",/' /home/azacsnap/bin/$azacsnapSharedConfig
  ./azacsnap --configfile $azacsnapSharedConfig -c backup --volume other --prefix $sharedPrefix --retention $sharedRetent
  echo "aztools>azacsnap complete"
 else
  echo "Please select the correct choice for aztools execution. $1 is <sidadm>, $2 is node1, $3 is node2, $4 is node3, $5 is azcopy|azacsnap, $6 is data|logbackup|shared"
 fi
else
 echo "Please select the correct choice for aztools execution. $1 is <sidadm>, $2 is node1, $3 is node2, $4 is node3, $5 is azcopy|azacsnap, $6 is data|logbackup|shared"
fi
