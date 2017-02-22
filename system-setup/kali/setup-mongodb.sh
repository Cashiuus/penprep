#!/bin/bash
#-Metadata----------------------------------------------------#
# Filename: kali-mongodb.sh              (Update: 09-16-2015) #
#-Author------------------------------------------------------#
#  cashiuus - cashiuus@gmail.com                              #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#                                                             #
#
# Usage: 
#        
#-------------------------------------------------------------#


MONGO_VERSION='3.2.1'


### Replica Set Params
cfg="{
	_id: 'rs0',
	members: [
		{_id: 1, host: "localhost:27017"}
	]
}"


### Install Guide: https://docs.mongodb.org/manual/tutorial/install-mongodb-on-linux/
### Standalone Install MongoDB Method - https://github.com/lair-framework/lair/wiki/Installation
curl -o mongodb.tgz https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian71-"${MONGO_VERSION}".tgz
tar -zxf mongodb.tgz
mkdir -p db

./mongodb-linux-x86_64-debian71-"${MONGO_VERSION}"/bin/mongod --dbpath=db --bind_ip=localhost --quiet --nounixsocket --replSet rs0 &
# Binds on port 27017
sleep 5
./mongodb-linux-x86_64-debian71-"${MONGO_VERSION}"/bin/mongo localhost:27017 --eval "JSON.stringify(db.adminCommand({'replSetInitiate' : $cfg}))"
