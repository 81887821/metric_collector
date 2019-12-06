readonly remote_user="csl"
readonly target_hosts=("s1" "s2" "s3" "s4")
readonly script="remote_script.sh"
readonly remote_log_directory_base="/tmp/log-$(date --iso-8601)"
readonly local_log_directory_base="${HOME}/collected-logs/log-$(date --iso-8601)"
readonly sleep_interval="15s"
