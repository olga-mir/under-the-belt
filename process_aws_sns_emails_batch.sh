#!/bin/bash
set -euo pipefail

LOG_FILE=debug.log
>$LOG_FILE
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

INPUT_DIR=$1
OUTPUT_DIR=${2-outputSamples}
JSON_OUTPUT_FORMAT=${3-p} # 'p'/'c' final message is validated with `jq`always and is saved in 'p'retty or 'c'ompact or not saved otherwise

[[ -d $INPUT_DIR ]] || { echo "First argument must be a directory with input batch files" >&2; exit 1; }
mkdir -p $OUTPUT_DIR

# message json files that could not be processed will be saved here
UNSUCCESSFUL_FILES_DIR=$OUTPUT_DIR/errors
mkdir -p $UNSUCCESSFUL_FILES_DIR

# output every message in separate file
# filenames - 4 digits
current_batch_counter=0
file="$OUTPUT_DIR/0000.json"
global_counter=0

main() {
  echo Input: $INPUT_DIR
  echo Output: $OUTPUT_DIR

  shopt -s nullglob
  for f in $INPUT_DIR/*; do
    process_single_batch $f
  done

  unsuccessful=`ls -1 $UNSUCCESSFUL_FILES_DIR | wc -l`
  echo DONE. Processed $global_counter files, with $unsuccessful errors
  echo Results are stored in $OUTPUT_DIR, unsuccessful files are saved in $UNSUCCESSFUL_FILES_DIR
}

process_single_batch() {
  input_batch_file=$1
  step1_temp_file="step1_temp_file.txt"

  # pass1 - easy to get rid of redundant lines with sed
  echo processing: $input_batch_file
  echo "current counter: $global_counter"
  sed -e '/^[A-Z0-9]/d' $input_batch_file | sed -e 's~\[Quoted text hidden\]~}~g' | awk '!/SigningCertURL|UnsubscribeURL/' > $step1_temp_file

  re_message="(^\"Message\"[[:space:]]:[[:space:]]\")(.*)(\",)$"
  re_signature="(^\"Signature\"[[:space:]]:[[:space:]]\")(.*)"
  current_batch_counter=0

  # pass2 - modify some lines to make it valid json, as well as get rid of backslashes in payload
  while read line ; do
    if [ "${line}" = "{" ]; then
      echo $line > $file
    elif [ "${line}" = "}" ]; then
      echo $line >> $file
      end_current_file
    elif [[ "$line" =~ $re_message ]]; then
      # Message line is over-escaped by GMail, while backslashes are removed already, traliing and leading quotes
      # need to be removed separately, while keeping the comma in the end
      # "[{\"eventName... <-- in the beginning; in the end --> ...Id\":91559}]",
      echo "\"Message\":${BASH_REMATCH[2]}," >> $file
    elif [[ "$line" =~ $re_signature ]]; then
      # this is the last line in json chunk, remove the trailing comma
      echo "${line%?}" >> $file
    else
      echo $line >> $file
    fi
  done < $step1_temp_file
  rm $step1_temp_file
}

format_json_file() {
  if [ "$JSON_OUTPUT_FORMAT" = 'p' ]; then
    jq '.' $file > tmp.json && mv tmp.json $file
  elif [ "$JSON_OUTPUT_FORMAT" = 'c' ]; then
    jq -c '.' $file > tmp.json && mv tmp.json $file
  else
    jq '.' $file > /dev/null
  fi
  if [ $? -ne 0 ]; then
    echo Error in $file
    mv $file $UNSUCCESSFUL_FILES_DIR
  fi
}

end_current_file() {
  format_json_file
  current_batch_counter=$((current_batch_counter+1))
  global_counter=$((global_counter+1))
  filename="$(printf -- '%0004d' "$global_counter")"
  file="$OUTPUT_DIR/$filename.json"
}

main
