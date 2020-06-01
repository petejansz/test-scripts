#!/bin/sh

hostnames=(caaplboapp1 caaplboapp2 caaplhornetq1 caaplhornetq2 caaplcrmcorea1 caaplcrmcorea2 caaplcrmexta1 caaplcrmexta2 caaplintweb1 caaplintweb2 caaplppweb1 caaplppweb2 caaplppapp1 caaplppapp2)

IFS=$'\n' sorted=($(sort <<<"${hostnames[*]}"))
unset IFS

for host in ${sorted[*]}; do
  RESP=$(ssh $host "ntptime 2>&1" | grep time | grep -ve constant -e adj )
  GETTIME=$(echo $RESP | grep gettime )
  STATUS=$(echo $RESP | awk '{printf "%s code(%s):status(%s)", $1, $4, $5}')
  TIME=$(echo $RESP | awk -F, '{print $2}')
  HOST_IP=$(ping -c 1 $host|awk '/PING/{printf "%s %s \n", $2, $3}')
  echo "$HOST_IP => $STATUS, $TIME"
done
