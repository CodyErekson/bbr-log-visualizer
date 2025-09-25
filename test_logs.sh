#!/usr/bin/env bash

# Function to display help information
show_help() {
    cat << EOF
Usage: $0 [RATE] [OPTIONS]

Generate random log messages and send them to the log visualizer REST endpoint.

ARGUMENTS:
    RATE                    Number of messages per second to generate (default: 5)

OPTIONS:
    -h, --help             Show this help message and exit
    -a, --all              Use all log levels (emergency, alert, critical, error,
                          warning, notice, info, debug). Default uses only
                          error, warning, info, debug.
    -s, --summary          Track and display statistics for each log level
    -d, --debug            Enable debug logging of sent messages to console

EXAMPLES:
    $0                     # Generate 5 messages per second (default levels)
    $0 10                  # Generate 10 messages per second
    $0 0.5                 # Generate 1 message every 2 seconds
    $0 --all               # Use all log levels at default rate
    $0 10 --all            # Generate 10 messages per second with all levels
    $0 --summary           # Generate with statistics tracking
    $0 10 --all --summary  # Generate 10 messages per second with all levels and stats
    $0 --help              # Show this help message

DESCRIPTION:
    This script generates random log messages with different severity levels
    and sends them to the log visualizer server running on localhost:2069. 
    Each message includes a timestamp and realistic log content appropriate 
    for its severity level.

    By default, only error, warning, info, and debug levels are used. Use
    the --all option to include emergency, alert, critical, and notice levels.
    Use the --summary option to track and display statistics when the script stops.

    Press Ctrl+C to stop the script.

EOF
}

# Initialize variables
RATE=5
USE_ALL_LEVELS=false
ENABLE_SUMMARY=false
ENABLE_DEBUG=false
ENDPOINT="http://localhost:2069/logs"

# Initialize counters for each log level (only if summary is enabled)
declare -A LOG_COUNTERS
for level in emergency alert critical error warning notice info debug; do
    LOG_COUNTERS[$level]=0
done

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--all)
            USE_ALL_LEVELS=true
            shift
            ;;
        -s|--summary)
            ENABLE_SUMMARY=true
            shift
            ;;
        -d|--debug)
            ENABLE_DEBUG=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            # Assume it's the rate parameter
            if [[ "$1" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                RATE="$1"
            else
                echo "Invalid rate value: $1"
                echo "Rate must be a number"
                exit 1
            fi
            shift
            ;;
    esac
done

# Set log levels based on --all option
if [ "$USE_ALL_LEVELS" = true ]; then
    LOG_LEVELS=("emergency" "alert" "critical" "error" "warning" "notice" "info" "debug")
else
    LOG_LEVELS=("error" "warning" "info" "debug")
fi

# Sample log messages for each level
EMERGENCY_MESSAGES=(
    "System is unusable: complete service outage"
    "All systems down, immediate intervention required"
    "Fatal system failure: data center power loss"
    "Emergency shutdown initiated: critical infrastructure failure"
    "System emergency: catastrophic data loss detected"
    "Emergency alert: security breach in progress"
    "Critical emergency: system compromise detected"
    "All backup systems failed"
    "System emergency: complete network failure"
    "Critical service dependencies unavailable"
)

ALERT_MESSAGES=(
    "Immediate action required - system degradation"
    "Security alert: suspicious activity detected"
    "Resource exhaustion imminent"
    "Service performance below acceptable threshold"
    "Configuration drift detected"
    "Backup process failed - manual intervention needed"
    "Disk space critically low on primary storage"
    "Database replication lag exceeds threshold"
    "External service dependency unavailable"
    "Authentication service experiencing issues"
)

CRITICAL_MESSAGES=(
    "Database cluster node failure"
    "Application server unresponsive"
    "Memory leak detected in core service"
    "Network partition affecting data consistency"
    "Storage array experiencing hardware failure"
    "Load balancer health check failures"
    "Message queue processing stopped"
    "Cache cluster node down"
    "SSL certificate expired"
    "Service discovery registry unavailable"
)

ERROR_MESSAGES=(
    "Database connection failed: timeout after 30 seconds"
    "Failed to authenticate user: invalid credentials"
    "Memory allocation error: insufficient heap space"
    "Network request failed: connection refused"
    "File system error: permission denied"
    "API rate limit exceeded: too many requests"
    "Critical system failure: service unavailable"
    "Data corruption detected in cache layer"
    "SSL certificate validation failed"
    "Out of disk space: cannot write to log file"
)

WARNING_MESSAGES=(
    "High memory usage detected: 85% of available memory"
    "Slow database query detected: 2.5s execution time"
    "Deprecated API endpoint used: will be removed in v2.0"
    "Cache miss rate above threshold: 15%"
    "Network latency spike detected: 500ms average"
    "Configuration file not found: using defaults"
    "User session expired: redirecting to login"
    "Backup process taking longer than expected"
    "Resource cleanup needed: temporary files accumulating"
    "Performance degradation in search index"
)

NOTICE_MESSAGES=(
    "System maintenance scheduled for tonight"
    "New feature deployed successfully"
    "User account created: user_id=12345"
    "Configuration change applied"
    "Service restart completed"
    "Database optimization completed"
    "Security patch applied"
    "Load balancer configuration updated"
    "Monitoring thresholds adjusted"
    "Backup verification completed"
)

INFO_MESSAGES=(
    "User login successful: user_id=12345"
    "New user registration completed"
    "Data backup completed successfully"
    "System health check passed"
    "Cache refreshed: 1000 entries updated"
    "API request processed: GET /api/users"
    "Database migration completed: version 1.2.3"
    "Scheduled task executed: daily cleanup"
    "Configuration reloaded: new settings applied"
    "WebSocket connection established"
)

DEBUG_MESSAGES=(
    "Function entry: processUserData()"
    "Variable value: userId=12345, sessionId=abc123"
    "Database query executed: SELECT * FROM users"
    "Cache lookup: key=user:12345, hit=true"
    "HTTP request headers: Content-Type=application/json"
    "Validation passed: email format correct"
    "Loop iteration: i=5, total=10"
    "Memory usage: 45MB allocated"
    "Timer started: operation_timeout=30s"
    "Configuration loaded: debug_mode=true"
)

# Function to get random message for a given level
get_random_message() {
    local level=$1
    case $level in
        "emergency")
            echo "${EMERGENCY_MESSAGES[$RANDOM % ${#EMERGENCY_MESSAGES[@]}]}"
            ;;
        "alert")
            echo "${ALERT_MESSAGES[$RANDOM % ${#ALERT_MESSAGES[@]}]}"
            ;;
        "critical")
            echo "${CRITICAL_MESSAGES[$RANDOM % ${#CRITICAL_MESSAGES[@]}]}"
            ;;
        "error")
            echo "${ERROR_MESSAGES[$RANDOM % ${#ERROR_MESSAGES[@]}]}"
            ;;
        "warning")
            echo "${WARNING_MESSAGES[$RANDOM % ${#WARNING_MESSAGES[@]}]}"
            ;;
        "notice")
            echo "${NOTICE_MESSAGES[$RANDOM % ${#NOTICE_MESSAGES[@]}]}"
            ;;
        "info")
            echo "${INFO_MESSAGES[$RANDOM % ${#INFO_MESSAGES[@]}]}"
            ;;
        "debug")
            echo "${DEBUG_MESSAGES[$RANDOM % ${#DEBUG_MESSAGES[@]}]}"
            ;;
    esac
}

# Function to display summary table
show_summary() {
    if [ "$ENABLE_SUMMARY" = false ]; then
        echo ""
        echo "Script stopped. Use --summary flag to see statistics."
        echo ""
        return
    fi
    
    echo ""
    echo "=========================================="
    echo "           LOG GENERATION SUMMARY"
    echo "=========================================="
    echo ""
    
    # Calculate total messages sent
    local total=0
    for level in emergency alert critical error warning notice info debug; do
        total=$((total + LOG_COUNTERS[$level]))
    done
    
    if [ $total -eq 0 ]; then
        echo "No messages were sent."
        echo ""
        return
    fi
    
    # Display table header
    printf "%-12s %8s %8s\n" "LOG LEVEL" "COUNT" "PERCENT"
    echo "----------------------------------------"
    
    # Display each level with count and percentage
    for level in emergency alert critical error warning notice info debug; do
        local count=${LOG_COUNTERS[$level]}
        if [ $count -gt 0 ]; then
            local percentage=$((count * 100 / total))
            printf "%-12s %8d %7d%%\n" "$level" "$count" "$percentage"
        fi
    done
    
    echo "----------------------------------------"
    printf "%-12s %8d %7d%%\n" "TOTAL" "$total" "100"
    echo ""
    echo "Script ran for $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds"
    echo "Average rate: $(echo "scale=1; $total / $SECONDS" | bc -l 2>/dev/null || echo "N/A") messages/second"
    echo ""
}

# Function to handle Ctrl+C (SIGINT)
cleanup() {
    echo ""
    echo "Received interrupt signal. Stopping log generation..."
    show_summary
    exit 0
}

# Set up signal handler for Ctrl+C
trap cleanup SIGINT

# Function to send log message
send_log() {
    local level=$1
    local message=$2
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Increment counter for this log level (only if summary is enabled)
    if [ "$ENABLE_SUMMARY" = true ]; then
        LOG_COUNTERS[$level]=$((${LOG_COUNTERS[$level]} + 1))
    fi
    
    local json_data=$(cat <<EOF
{
    "level": "$level",
    "message": "$message",
    "timestamp": "$timestamp",
    "source": "test_logs.sh"
}
EOF
)
    
    # Capture curl exit code immediately to avoid it being overwritten
    local curl_exit_code=0
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$json_data" \
        "$ENDPOINT" > /dev/null || curl_exit_code=$?

    # Only log sent messages if debug mode is enabled
    if [ "$ENABLE_DEBUG" = true ]; then
        if [ $curl_exit_code -eq 0 ]; then
            echo "[$(date '+%H:%M:%S')] Sent $level: $message"
        else
            echo "[$(date '+%H:%M:%S')] Failed to send $level: $message"
        fi
    fi
}

# Function to calculate sleep interval
calculate_sleep() {
    # Convert rate to sleep interval (1 second / rate)
    echo "scale=3; 1.0 / $RATE" | bc -l
}

# Main execution
echo "Starting log generator..."
echo "Rate: $RATE messages per second"
echo "Endpoint: $ENDPOINT"
echo "Press Ctrl+C to stop"
echo ""

# Start timing
SECONDS=0

# Check if bc is available for floating point arithmetic
if ! command -v bc &> /dev/null; then
    echo "Warning: 'bc' command not found. Using integer division for sleep calculation."
    SLEEP_INTERVAL=$((1000 / RATE))
    USE_BC=false
else
    SLEEP_INTERVAL=$(calculate_sleep)
    USE_BC=true
fi

# Function to select log level with custom probability distribution
select_log_level() {
    # Define probability weights (out of 1000 for precision)
    # 10% each: emergency, alert, critical, error (40% total)
    # 20% each: warning, notice (40% total) 
    # 30%: info
    # 40%: debug
    
    # Check which levels are available and calculate individual weights
    local total_weight=0
    local weights=()
    local level_names=()
    
    # Emergency (10%)
    if [[ " ${LOG_LEVELS[*]} " =~ " emergency " ]]; then
        weights+=(100)
        level_names+=("emergency")
        total_weight=$((total_weight + 100))
    fi
    
    # Alert (10%)
    if [[ " ${LOG_LEVELS[*]} " =~ " alert " ]]; then
        weights+=(100)
        level_names+=("alert")
        total_weight=$((total_weight + 100))
    fi
    
    # Critical (10%)
    if [[ " ${LOG_LEVELS[*]} " =~ " critical " ]]; then
        weights+=(100)
        level_names+=("critical")
        total_weight=$((total_weight + 100))
    fi
    
    # Error (10%)
    if [[ " ${LOG_LEVELS[*]} " =~ " error " ]]; then
        weights+=(100)
        level_names+=("error")
        total_weight=$((total_weight + 100))
    fi
    
    # Warning (20%)
    if [[ " ${LOG_LEVELS[*]} " =~ " warning " ]]; then
        weights+=(200)
        level_names+=("warning")
        total_weight=$((total_weight + 200))
    fi
    
    # Notice (20%)
    if [[ " ${LOG_LEVELS[*]} " =~ " notice " ]]; then
        weights+=(200)
        level_names+=("notice")
        total_weight=$((total_weight + 200))
    fi
    
    # Info (30%)
    if [[ " ${LOG_LEVELS[*]} " =~ " info " ]]; then
        weights+=(300)
        level_names+=("info")
        total_weight=$((total_weight + 300))
    fi
    
    # Debug (40%)
    if [[ " ${LOG_LEVELS[*]} " =~ " debug " ]]; then
        weights+=(400)
        level_names+=("debug")
        total_weight=$((total_weight + 400))
    fi
    
    # If no levels found, fallback to equal probability
    if [ ${#level_names[@]} -eq 0 ]; then
        echo "${LOG_LEVELS[$RANDOM % ${#LOG_LEVELS[@]}]}"
        return
    fi
    
    # Generate random number (0 to total_weight-1)
    local random_value=$((RANDOM % total_weight))
    
    # Find which level the random value falls into using cumulative weights
    local cumulative=0
    for i in "${!weights[@]}"; do
        cumulative=$((cumulative + ${weights[$i]}))
        if [ $random_value -lt $cumulative ]; then
            echo "${level_names[$i]}"
            return
        fi
    done
    
    # Fallback (should never reach here)
    echo "${level_names[-1]}"
}

# Main loop
while true; do
    # Select random log level with debug bias
    level=$(select_log_level)
    
    # Get random message for the level
    message=$(get_random_message "$level")
    
    # Send the log message
    send_log "$level" "$message"
    
    # Sleep for the calculated interval
    if [ "$USE_BC" = true ]; then
        sleep "$SLEEP_INTERVAL"
    else
        sleep 0.$SLEEP_INTERVAL
    fi
done
