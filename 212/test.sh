#!/bin/bash

# IP: the POD ID, TIME: sleep time between endpoint changes
IP=$1
TIME=$2
NSNAME=$3
EPNAME=$4

if [[ -z "$IP" ]] || [[ -z "$TIME" ]] || [[ -z "$NSNAME" ]] || [[ -z "$EPNAME" ]]
then
  echo "Auguments: [POD IP] [SLEEP TIME] [K8S NAMESPACE NAME] [K8S ENDPOINT NAME]"
  exit
fi

echo "Namespace: $NSNAME, Endpoint: $EPNAME, POD IP: $IP, Sleep Time: $TIME"

echo "remove endpoint $IP:8001"
curl -X PATCH "http://$IP:8001/api/7/http/keyvals/canary" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"abswitch\": \"1\"}"
STARTTIME=$(date +%s)
EP=$(kubectl get ep -n $NSNAME $EPNAME --no-headers | awk '{print $2}')

while [[ "$(kubectl get ep -n $NSNAME $EPNAME --no-headers | awk '{print $2}')" == *"$IP"* ]];
do
    echo $(date) $(kubectl get ep -n $NSNAME $EPNAME --no-headers | awk '{print $2}') $(kubectl get pods -o wide -n $NSNAME | grep $IP | awk '{print $2, $3, $6}')
    sleep 1;
done

echo $(date) $(kubectl get ep -n $NSNAME $EPNAME --no-headers | awk '{print $2}') $(kubectl get pods -o wide -n $NSNAME | grep $IP | awk '{print $2, $3, $6}')

ENDTIME=$(date +%s)

echo "remove $IP:8001 spend $(($ENDTIME - $STARTTIME)) seconds"

echo "sleep $TIME seconds"
sleep $TIME

echo "add endpoint $IP:8001"
curl -X PATCH "http://$IP:8001/api/7/http/keyvals/canary" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"abswitch\": \"0\"}"
ADDSTARTTIME=$(date +%s)
while [[ "$(kubectl get ep -n $NSNAME $EPNAME --no-headers | awk '{print $2}')" != *"$IP"* ]];
do
    echo $(date) $(kubectl get ep -n $NSNAME $EPNAME --no-headers | awk '{print $2}') $(kubectl get pods -o wide -n $NSNAME | grep $IP | awk '{print $2, $3, $6}')
    sleep 1;
done

echo $(date) $(kubectl get ep -n $NSNAME $EPNAME --no-headers | awk '{print $2}') $(kubectl get pods -o wide -n $NSNAME | grep $IP | awk '{print $2, $3, $6}')

ADDENDTIME=$(date +%s)

echo "add $IP:8001 spend $(($ADDENDTIME - $ADDSTARTTIME)) seconds"
