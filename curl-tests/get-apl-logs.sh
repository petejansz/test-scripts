#!/bin/sh

ENV_NAME=apl
YEAR=$( date +%Y )
cd ~/cas/$ENV_NAME

for HOST in "ca${ENV_NAME}ppapp1" "ca${ENV_NAME}ppapp2"; do
   REMOTE_FILE=$( ssh $HOST ls -tr "/opt/jboss/server/sec-gateway/log/verbosegc.log-${YEAR}-*" | tail -1 )
   BASENAME="sec-gateway-$( basename $REMOTE_FILE )"
   scp -p $HOST:$REMOTE_FILE "${HOST}-${BASENAME}"
done

for HOST in "ca${ENV_NAME}crmcorea1" "ca${ENV_NAME}crmcorea2"; do
   REMOTE_FILE=$( ssh $HOST ls -tr "/opt/jboss/server/crm-core/log/verbosegc.log-${YEAR}-*" | tail -1 )
   BASENAME="crm-core-$( basename $REMOTE_FILE )"
   scp -p $HOST:$REMOTE_FILE "${HOST}-${BASENAME}"
done

for HOST in "ca${ENV_NAME}crmcorea1" "ca${ENV_NAME}crmcorea2"; do
   REMOTE_FILE=$( ssh $HOST ls -tr "/opt/jboss/server/pd-crm-processes/log/verbosegc.log-${YEAR}-*" | tail -1 )
   BASENAME="pd-crm-processes-$( basename $REMOTE_FILE )"
   scp -p $HOST:$REMOTE_FILE "${HOST}-${BASENAME}"
done

for HOST in "ca${ENV_NAME}crmexta1" "ca${ENV_NAME}crmexta2"; do
   REMOTE_FILE=$( ssh $HOST ls -tr "/opt/jboss/server/crm-ext/log/verbosegc.log-${YEAR}-*" | tail -1 )
   BASENAME="crm-ext-$( basename $REMOTE_FILE )"
   scp -p $HOST:$REMOTE_FILE "${HOST}-${BASENAME}"
done

for HOST in "ca${ENV_NAME}hornetq1" "ca${ENV_NAME}hornetq2" ; do
   REMOTE_FILE=$( ssh $HOST ls -tr "/opt/jboss/server/broker/log/verbosegc.log-${YEAR}-*" | tail -1 )
   BASENAME="broker-$( basename $REMOTE_FILE )"
   scp -p $HOST:$REMOTE_FILE "${HOST}-${BASENAME}"
done

TAR_FILENAME="${ENV_NAME}-verbosegc-logs-$(date +%F).tar"
VERBOSEGC_FILES=$( ls ca*-verbosegc.log-${YEAR}-??-??-??-?? )
tar cvf $TAR_FILENAME $VERBOSEGC_FILES 
gzip --force $TAR_FILENAME
rm -f $VERBOSEGC_FILES 

ls -ld "$PWD/${TAR_FILENAME}.gz"
