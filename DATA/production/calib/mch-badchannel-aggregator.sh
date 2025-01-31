#!/bin/bash

source common/setenv.sh

# ---------------------------------------------------------------------------------------------------------------------
# Set general arguments
ARGS_ALL="--session default --severity $SEVERITY --shm-segment-size $SHMSIZE $ARGS_ALL_EXTRA"
ARGS_ALL+=" --infologger-severity $INFOLOGGER_SEVERITY"
ARGS_ALL+=" --monitoring-backend influxdb-unix:///tmp/telegraf.sock --resources-monitoring 60"
if [ $SHMTHROW == 0 ]; then
  ARGS_ALL+=" --shm-throw-bad-alloc 0"
fi
if [ $NORATELOG == 1 ]; then
  ARGS_ALL+=" --fairmq-rate-logging 0"
fi
ARGS_ALL_CONFIG="NameConf.mDirGRP=$FILEWORKDIR;NameConf.mDirGeom=$FILEWORKDIR;NameConf.mDirCollContext=$FILEWORKDIR;NameConf.mDirMatLUT=$FILEWORKDIR;keyval.input_dir=$FILEWORKDIR;keyval.output_dir=/dev/null;$ALL_EXTRA_CONFIG"

PROXY_INSPEC="A:MCH/PDIGITS/0"

BADCHANNEL_CONFIG="${ARGS_ALL_CONFIG};MCHBadChannelCalibratorParam.minRequiredNofEntriesPerChannel=100;MCHBadChannelCalibratorParam.minRequiredCalibratedFraction=0.5;MCHBadChannelCalibratorParam.onlyAtEndOfStream=true"

WORKFLOW="o2-dpl-raw-proxy $ARGS_ALL --proxy-name mch-badchannel-input-proxy --dataspec \"$PROXY_INSPEC\" --network-interface ib0 --channel-config \"name=mch-badchannel-input-proxy,method=bind,type=pull,rateLogging=0,transport=zeromq\" | "
WORKFLOW+="o2-calibration-mch-badchannel-calib-workflow $ARGS_ALL --configKeyValues \"$BADCHANNEL_CONFIG\" | "
WORKFLOW+="o2-calibration-ccdb-populator-workflow $ARGS_ALL --configKeyValues \"$ARGS_ALL_CONFIG\" --ccdb-path=\"http://o2-ccdb.internal\" --sspec-min 0 --sspec-max 0 | "
WORKFLOW+="o2-calibration-ccdb-populator-workflow $ARGS_ALL --configKeyValues \"$ARGS_ALL_CONFIG\" --ccdb-path=\"http://alio2-cr1-flp199.cern.ch:8083\" --sspec-min 1 --sspec-max 1 --name-extention dcs| "
WORKFLOW+="o2-dpl-run $ARGS_ALL $GLOBALDPLOPT"

if [ $WORKFLOWMODE == "print" ]; then
  echo Workflow command:
  echo $WORKFLOW | sed "s/| */|\n/g"
else
  # Execute the command we have assembled
  WORKFLOW+=" --$WORKFLOWMODE"
  eval $WORKFLOW
fi