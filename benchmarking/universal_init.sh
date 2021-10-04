#!/bin/bash

# Universal mode init script. Run this script without params on each dataplane. Pulls message from
# queue to find more specific script / data to run. This currently assumes all dataplane workers
# are interchangeable wrt platform and performance.
# XXX remove hard coded queue and region

mkdir /home/ubuntu/.aws
cat >/home/ubuntu/.aws/config <<EOF
[default]
region=us-east-2
EOF

# One queue to rule them all
aws sqs receive-message --queue-url https://sqs.us-east-2.amazonaws.com/151743893450/kuma-benchmarking.fifo --max-number-of-messages 1 > /home/ubuntu/workload_message.json
workload_message=$(jq -r '.Messages[0].Body' /home/ubuntu/workload_message.json)
workload_rcpt=$(jq -r '.Messages[0].ReceiptHandle' /home/ubuntu/workload_message.json)

# Message format $BOOTSTRAP_URL|$BOOTSTRAP_PARAMS
bootstrap_url=$(echo $workload_message | cut -d'|' -f1)
bootstrap_params=$(echo $workload_message | cut -d'|' -f2)

aws s3 cp $bootstrap_url /home/ubuntu/bootstrap.sh
chmod a+x /home/ubuntu/bootstrap.sh

# Want to allow bootstrap.sh to run forever, so download of script considered "success"; also
# no great way to recover from error.
aws sqs delete-message --queue-url https://sqs.us-east-2.amazonaws.com/151743893450/kuma-benchmarking.fifo --receipt-handle $workload_rcpt

# Don't quote bootstrap params; pass as individual params
/home/ubuntu/bootstrap.sh $bootstrap_params
