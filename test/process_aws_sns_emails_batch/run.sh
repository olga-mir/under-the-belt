#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$DIR/../../process_aws_sns_emails_batch.sh ${DIR}/inputs ${DIR}/outputs > /dev/null
diff -r ${DIR}/expected_outputs ${DIR}/outputs > /dev/null
# TODO - to level up
if [ $? -ne 0 ]; then
  echo FAIL
else
  echo PASS
fi
