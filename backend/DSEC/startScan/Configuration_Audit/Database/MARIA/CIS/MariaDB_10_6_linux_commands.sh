#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input.json>"
  exit 1
fi

input_file="$1"
output_file="final.json"

declare -A json_map
declare -A db_commands

db_commands["3_1_Ensure_datadir_Has_Appropriate_Permissions_Automated_"]="sudo ls -ld {{DATADIR}} | grep \"drwxr-x---.*mysql.*mysql\""
db_commands["3_2_Ensure_log_bin_basename_Files_Have_Appropriate_Permissions_Automated_"]="ls -l {{LOG_BIN_BASENAME}}.* | grep -v '^-rw-rw----.*mysql.*mysql'"
db_commands["3_3_Ensure_log_error_Has_Appropriate_Permissions_Automated_"]="ls -l {{LOG_ERROR}} | grep '^-rw-------.*mysql.*mysql.*$'"
db_commands["3_4_Ensure_slow_query_log_Has_Appropriate_Permissions_Automated_"]="ls -l {{SLOW_QUERY_LOG_FILE}}  | grep -Pv '^-rw-rw----\s+.*mysql\s+mysql'"
db_commands["3_5_Ensure_relay_log_basename_Files_Have_Appropriate_Permissions_Automated_"]="ls -l  {{RELAY_LOG_BASENAME}}.* | grep -v '^-rw-rw----.*mysql.*mysql'"
db_commands["3_8_Ensure_Plugin_Directory_Has_Appropriate_Permissions_Automated_"]="ls -ld {{PLUGIN_DIR}} | grep \"dr-xr-x---\|dr-xr-xr--\" | grep \"plugin\""

if [ -f "$input_file" ]; then
  while IFS= read -r item; do
    name=$(echo "$item" | jq -r '.Name')
    json_map["$name"]="$item"
  done < <(jq -c '.[]' "$input_file")
fi

result=$( grep MYSQL_PWD /home/*/.{bashrc,profile,bash_profile} 2>&1 | sed 's/"/\\\"/g' )
json_map["1_6_Verify_That_MYSQL_PWD_is_Not_Set_in_Users_Profiles_Automated_"]="{\"Name\": \"1_6_Verify_That_MYSQL_PWD_is_Not_Set_in_Users_Profiles_Automated_\", \"Result\": [{\"VARIABLE_NAME\": \"Command\", \"VARIABLE_VALUE\": \"$result\"}]}"

result=$( my_print_defaults mysqld | grep allow-suspicious-udfs 2>&1 | sed 's/"/\\\"/g' )
json_map["4_3_Ensure_allow_suspicious_udfs_is_Set_to_OFF_Automated_"]="{\"Name\": \"4_3_Ensure_allow_suspicious_udfs_is_Set_to_OFF_Automated_\", \"Result\": [{\"VARIABLE_NAME\": \"Command\", \"VARIABLE_VALUE\": \"$result\"}]}"

for name in "${!db_commands[@]}"; do
  raw_entry="${json_map[$name]}"
  if [ -n "$raw_entry" ]; then
    cmd_template="${db_commands[$name]}"
    result_json=$(echo "$raw_entry" | jq -c '.Result // empty | .[]')
    if [ -z "$result_json" ]; then
      valid_substitution=false
    else
      valid_substitution=true
      for pair in $result_json; do
        var=$(echo "$pair" | jq -r '.VARIABLE_NAME')
        val=$(echo "$pair" | jq -r '.VARIABLE_VALUE')
        if [ "$val" = "null" ] || [ -z "$val" ]; then
          valid_substitution=false
          break
        fi
        cmd_template="${cmd_template//\{\{$var\}\}/$val}"
      done
    fi
    if [ "$valid_substitution" = true ]; then
      result=$(eval "$cmd_template" 2>&1 | tr '\n' ',' | sed 's/,$//' | sed 's/"/\\\"/g')
    else
      result="it is not enabled"
    fi
    json_map["$name"]="{\"Name\": \"$name\", \"Result\": [{\"VARIABLE_NAME\": \"Command\", \"VARIABLE_VALUE\": \"$result\"}]}"
  fi
done

output_items=()
for item in "${json_map[@]}"; do
  output_items+=("$item")
done

printf "[\n%s\n]" "$(IFS=,; echo "${output_items[*]}")" > "$output_file"
