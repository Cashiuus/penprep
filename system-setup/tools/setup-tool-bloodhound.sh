#!/bin/bash



ulimit -n 40000

sudo neo4j console &

# Change default neo4j:neo4j to another password
echo -e "[*] Opening firefox to neo4j. Change the default neo4j:neo4j to something else!"
sleep 15s
firefox --new-tab http://localhost:7474 &


sleep 10s
bloodhound &
