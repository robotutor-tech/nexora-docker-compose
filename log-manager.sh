#!/bin/bash

# Nexora Log Management Script
# Helps manage and view logs for all Nexora services running on Raspberry Pi

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service names
SERVICES=(
    "zookeeper"
    "kafka"
    "redis"
    "mongo"
    "emqx"
    "nexora-backend"
    "nexora-bff"
    "mqtt-handler"
    "nexora-ui"
    "nexora-nginx"
)

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show menu
show_menu() {
    echo ""
    echo "======================================"
    echo "  Nexora Log Management Tool"
    echo "======================================"
    echo "1.  View logs for a specific service"
    echo "2.  View logs for all services"
    echo "3.  Search logs for errors"
    echo "4.  Search logs for custom pattern"
    echo "5.  Export logs to file"
    echo "6.  Check log file sizes"
    echo "7.  Check disk usage"
    echo "8.  View container stats"
    echo "9.  View service status"
    echo "10. Tail logs (last 100 lines)"
    echo "11. View logs since time period"
    echo "12. Clean old logs (careful!)"
    echo "13. View volume logs (Kafka/Mongo/EMQX)"
    echo "0.  Exit"
    echo "======================================"
    echo ""
}

# Function to select service
select_service() {
    echo ""
    echo "Select a service:"
    for i in "${!SERVICES[@]}"; do
        echo "$((i+1)). ${SERVICES[$i]}"
    done
    echo ""
    read -p "Enter service number: " service_num

    if [[ $service_num -ge 1 && $service_num -le ${#SERVICES[@]} ]]; then
        echo "${SERVICES[$((service_num-1))]}"
    else
        echo ""
    fi
}

# Function to view logs
view_logs() {
    service=$(select_service)
    if [ -n "$service" ]; then
        print_info "Viewing logs for $service (Ctrl+C to exit)..."
        docker logs -f --timestamps "$service"
    else
        print_error "Invalid service selection"
    fi
}

# Function to view all logs
view_all_logs() {
    print_info "Viewing logs for all services (Ctrl+C to exit)..."
    docker-compose logs -f --timestamps
}

# Function to search for errors
search_errors() {
    service=$(select_service)
    if [ -n "$service" ]; then
        print_info "Searching for errors in $service..."
        echo ""
        docker logs "$service" 2>&1 | grep -i "error\|exception\|fatal" || print_warning "No errors found"
    else
        print_error "Invalid service selection"
    fi
}

# Function to search custom pattern
search_pattern() {
    service=$(select_service)
    if [ -n "$service" ]; then
        echo ""
        read -p "Enter search pattern: " pattern
        if [ -n "$pattern" ]; then
            print_info "Searching for '$pattern' in $service..."
            echo ""
            docker logs "$service" 2>&1 | grep -i "$pattern" || print_warning "Pattern not found"
        fi
    else
        print_error "Invalid service selection"
    fi
}

# Function to export logs
export_logs() {
    service=$(select_service)
    if [ -n "$service" ]; then
        timestamp=$(date +%Y%m%d-%H%M%S)
        filename="${service}-logs-${timestamp}.log"
        print_info "Exporting logs for $service to $filename..."
        docker logs "$service" > "$filename" 2>&1
        print_success "Logs exported to $filename"
        ls -lh "$filename"
    else
        print_error "Invalid service selection"
    fi
}

# Function to check log sizes
check_log_sizes() {
    print_info "Checking Docker log file sizes..."
    echo ""

    for service in "${SERVICES[@]}"; do
        container_id=$(docker ps -q -f "name=$service" 2>/dev/null)
        if [ -n "$container_id" ]; then
            log_path=$(docker inspect --format='{{.LogPath}}' "$container_id" 2>/dev/null)
            if [ -f "$log_path" ]; then
                size=$(du -h "$log_path" | cut -f1)
                printf "%-20s: %s\n" "$service" "$size"
            fi
        fi
    done

    echo ""
    print_info "Checking volume log sizes..."
    echo ""

    # Check Kafka logs
    if docker volume ls | grep -q "kafka-logs"; then
        kafka_size=$(docker run --rm -v nexora-docker-compose_kafka-logs:/logs alpine sh -c "du -sh /logs 2>/dev/null | cut -f1" || echo "N/A")
        printf "%-20s: %s\n" "kafka-logs volume" "$kafka_size"
    fi

    # Check Mongo logs
    if docker volume ls | grep -q "mongo-logs"; then
        mongo_size=$(docker run --rm -v nexora-docker-compose_mongo-logs:/logs alpine sh -c "du -sh /logs 2>/dev/null | cut -f1" || echo "N/A")
        printf "%-20s: %s\n" "mongo-logs volume" "$mongo_size"
    fi

    # Check EMQX logs
    if docker volume ls | grep -q "emqx-logs"; then
        emqx_size=$(docker run --rm -v nexora-docker-compose_emqx-logs:/logs alpine sh -c "du -sh /logs 2>/dev/null | cut -f1" || echo "N/A")
        printf "%-20s: %s\n" "emqx-logs volume" "$emqx_size"
    fi
}

# Function to check disk usage
check_disk_usage() {
    print_info "Overall disk usage:"
    echo ""
    df -h

    echo ""
    print_info "Docker disk usage:"
    echo ""
    docker system df
}

# Function to view container stats
view_stats() {
    print_info "Container resource usage (Ctrl+C to exit)..."
    echo ""
    docker stats
}

# Function to view service status
view_status() {
    print_info "Service status:"
    echo ""
    docker-compose ps
}

# Function to tail logs
tail_logs() {
    service=$(select_service)
    if [ -n "$service" ]; then
        print_info "Last 100 lines of $service logs (Ctrl+C to exit)..."
        docker logs --tail 100 -f --timestamps "$service"
    else
        print_error "Invalid service selection"
    fi
}

# Function to view logs since time
logs_since() {
    service=$(select_service)
    if [ -n "$service" ]; then
        echo ""
        echo "Select time period:"
        echo "1. Last 1 hour"
        echo "2. Last 6 hours"
        echo "3. Last 24 hours"
        echo "4. Custom time"
        echo ""
        read -p "Enter choice: " time_choice

        case $time_choice in
            1)
                print_info "Viewing logs since 1 hour ago..."
                docker logs --since 1h --timestamps "$service"
                ;;
            2)
                print_info "Viewing logs since 6 hours ago..."
                docker logs --since 6h --timestamps "$service"
                ;;
            3)
                print_info "Viewing logs since 24 hours ago..."
                docker logs --since 24h --timestamps "$service"
                ;;
            4)
                read -p "Enter time (e.g., 2h, 30m, 2026-01-25T10:00:00): " custom_time
                print_info "Viewing logs since $custom_time..."
                docker logs --since "$custom_time" --timestamps "$service"
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
    else
        print_error "Invalid service selection"
    fi
}

# Function to clean logs
clean_logs() {
    print_warning "WARNING: This will remove old container logs!"
    echo ""
    echo "Options:"
    echo "1. Clean all unused Docker resources (images, containers, networks)"
    echo "2. Clean log volumes only (kafka-logs, mongo-logs, emqx-logs)"
    echo "3. Cancel"
    echo ""
    read -p "Enter choice: " clean_choice

    case $clean_choice in
        1)
            print_warning "This will clean ALL unused Docker resources..."
            read -p "Are you sure? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                print_info "Cleaning Docker system..."
                docker system prune -f
                print_success "Cleanup completed"
            else
                print_info "Cleanup cancelled"
            fi
            ;;
        2)
            print_warning "This will remove log volumes. Containers will be stopped first."
            echo ""
            docker-compose ps --services | while read service; do
                docker-compose ps | grep "$service" | grep "Up" > /dev/null && echo "  - $service"
            done
            echo ""
            read -p "Stop containers and clean log volumes? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                print_info "Stopping containers..."
                docker-compose down

                print_info "Removing log volumes..."
                docker volume rm nexora-docker-compose_kafka-logs 2>/dev/null && print_success "Removed kafka-logs" || true
                docker volume rm nexora-docker-compose_mongo-logs 2>/dev/null && print_success "Removed mongo-logs" || true
                docker volume rm nexora-docker-compose_emqx-logs 2>/dev/null && print_success "Removed emqx-logs" || true

                print_info "Restarting containers..."
                docker-compose up -d
                print_success "Cleanup completed and services restarted"
            else
                print_info "Cleanup cancelled"
            fi
            ;;
        3)
            print_info "Cleanup cancelled"
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to view volume logs
view_volume_logs() {
    echo ""
    echo "Select volume logs to view:"
    echo "1. Kafka logs"
    echo "2. MongoDB logs"
    echo "3. EMQX logs"
    echo ""
    read -p "Enter choice: " vol_choice

    case $vol_choice in
        1)
            print_info "Kafka log files:"
            docker exec -it kafka sh -c "ls -lah /var/log/kafka 2>/dev/null" || print_error "Cannot access Kafka logs"
            echo ""
            read -p "View server.log? (yes/no): " view_kafka
            if [ "$view_kafka" = "yes" ]; then
                docker exec -it kafka sh -c "tail -f /var/log/kafka/server.log" || print_error "Cannot view server.log"
            fi
            ;;
        2)
            print_info "MongoDB log files:"
            docker exec -it mongo sh -c "ls -lah /var/log/mongodb 2>/dev/null" || print_error "Cannot access MongoDB logs"
            echo ""
            read -p "View mongod.log? (yes/no): " view_mongo
            if [ "$view_mongo" = "yes" ]; then
                docker exec -it mongo sh -c "tail -f /var/log/mongodb/mongod.log" || print_error "Cannot view mongod.log"
            fi
            ;;
        3)
            print_info "EMQX log files:"
            docker exec -it emqx sh -c "ls -lah /opt/emqx/log 2>/dev/null" || print_error "Cannot access EMQX logs"
            echo ""
            read -p "Enter log file name to view (or press Enter to skip): " emqx_file
            if [ -n "$emqx_file" ]; then
                docker exec -it emqx sh -c "tail -f /opt/emqx/log/$emqx_file" || print_error "Cannot view $emqx_file"
            fi
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Main loop
main() {
    while true; do
        show_menu
        read -p "Enter your choice: " choice

        case $choice in
            1) view_logs ;;
            2) view_all_logs ;;
            3) search_errors ;;
            4) search_pattern ;;
            5) export_logs ;;
            6) check_log_sizes ;;
            7) check_disk_usage ;;
            8) view_stats ;;
            9) view_status ;;
            10) tail_logs ;;
            11) logs_since ;;
            12) clean_logs ;;
            13) view_volume_logs ;;
            0)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check if docker-compose is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_warning "docker-compose command not found. Using 'docker compose' instead."
    # Create alias if needed
    alias docker-compose='docker compose'
fi

# Run main function
main
