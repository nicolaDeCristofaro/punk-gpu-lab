#!/bin/bash

PROFILE=$1
INSTANCE_ID=$2

echo "Waiting for instance $INSTANCE_ID to reach 3/3 status checks..."

while true; do
  STATUS=$(aws ec2 describe-instance-status \
    --profile "$PROFILE" \
    --instance-ids "$INSTANCE_ID" \
    --query "InstanceStatuses[0].InstanceStatus.Status" \
    --output text)

  SYSTEM_STATUS=$(aws ec2 describe-instance-status \
    --profile "$PROFILE" \
    --instance-ids "$INSTANCE_ID" \
    --query "InstanceStatuses[0].SystemStatus.Status" \
    --output text)

  if [[ "$STATUS" == "ok" && "$SYSTEM_STATUS" == "ok" ]]; then
    echo "✅ Instance is ready: all 3/3 checks passed."
    break
  else
    echo "⏳ Still waiting... (InstanceStatus: $STATUS, SystemStatus: $SYSTEM_STATUS)"
    sleep 10
  fi
done