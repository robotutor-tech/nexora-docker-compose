#!/bin/bash

# Quick log viewing aliases and functions for Nexora
# Source this file in your ~/.bashrc or ~/.zshrc:
# source /path/to/nexora-docker-compose/log-aliases.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Quick log viewing functions
alias nlogs='docker-compose logs'
alias nlogsf='docker-compose logs -f'

# Individual service log aliases
alias logs-zk='docker logs -f --timestamps zookeeper'
alias logs-kafka='docker logs -f --timestamps kafka'
alias logs-redis='docker logs -f --timestamps redis'
alias logs-mongo='docker logs -f --timestamps mongo'
alias logs-emqx='docker logs -f --timestamps emqx'
alias logs-backend='docker logs -f --timestamps nexora-backend'
alias logs-bff='docker logs -f --timestamps nexora-bff'
alias logs-mqtt='docker logs -f --timestamps mqtt-handler'
alias logs-ui='docker logs -f --timestamps nexora-ui'
alias logs-nginx='docker logs -f --timestamps nexora-nginx'

# Tail logs (last 100 lines)
alias logs-zk-tail='docker logs --tail 100 -f --timestamps zookeeper'
alias logs-kafka-tail='docker logs --tail 100 -f --timestamps kafka'
alias logs-redis-tail='docker logs --tail 100 -f --timestamps redis'
alias logs-mongo-tail='docker logs --tail 100 -f --timestamps mongo'
alias logs-emqx-tail='docker logs --tail 100 -f --timestamps emqx'
alias logs-backend-tail='docker logs --tail 100 -f --timestamps nexora-backend'
alias logs-bff-tail='docker logs --tail 100 -f --timestamps nexora-bff'
alias logs-mqtt-tail='docker logs --tail 100 -f --timestamps mqtt-handler'
alias logs-ui-tail='docker logs --tail 100 -f --timestamps nexora-ui'
alias logs-nginx-tail='docker logs --tail 100 -f --timestamps nexora-nginx'

# Search for errors
nlogs-errors() {
    local service=$1
    if [ -z "$service" ]; then
        echo -e "${YELLOW}Usage: nlogs-errors <service-name>${NC}"
        echo "Example: nlogs-errors kafka"
        return 1
    fi
    echo -e "${BLUE}Searching for errors in $service...${NC}"
    docker logs "$service" 2>&1 | grep -i "error\|exception\|fatal"
}

# Search for custom pattern
nlogs-search() {
    local service=$1
    local pattern=$2
    if [ -z "$service" ] || [ -z "$pattern" ]; then
        echo -e "${YELLOW}Usage: nlogs-search <service-name> <pattern>${NC}"
        echo "Example: nlogs-search kafka 'connection'"
        return 1
    fi
    echo -e "${BLUE}Searching for '$pattern' in $service...${NC}"
    docker logs "$service" 2>&1 | grep -i "$pattern"
}

# View logs since time
nlogs-since() {
    local service=$1
    local time=$2
    if [ -z "$service" ] || [ -z "$time" ]; then
        echo -e "${YELLOW}Usage: nlogs-since <service-name> <time>${NC}"
        echo "Examples:"
        echo "  nlogs-since kafka 1h     # Last 1 hour"
        echo "  nlogs-since mongo 30m    # Last 30 minutes"
        echo "  nlogs-since redis 2h     # Last 2 hours"
        return 1
    fi
    echo -e "${BLUE}Viewing logs for $service since $time...${NC}"
    docker logs --since "$time" --timestamps "$service"
}

# Export logs
nlogs-export() {
    local service=$1
    if [ -z "$service" ]; then
        echo -e "${YELLOW}Usage: nlogs-export <service-name>${NC}"
        echo "Example: nlogs-export kafka"
        return 1
    fi
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local filename="${service}-logs-${timestamp}.log"
    echo -e "${BLUE}Exporting logs for $service to $filename...${NC}"
    docker logs "$service" > "$filename" 2>&1
    echo -e "${GREEN}Logs exported to $filename${NC}"
    ls -lh "$filename"
}

# Check container status
nstatus() {
    echo -e "${BLUE}Nexora Service Status:${NC}"
    docker-compose ps
}

# Check container stats
nstats() {
    echo -e "${BLUE}Nexora Resource Usage:${NC}"
    docker stats --no-stream
}

# Check disk usage
ndisk() {
    echo -e "${BLUE}Disk Usage:${NC}"
    df -h
    echo ""
    echo -e "${BLUE}Docker Disk Usage:${NC}"
    docker system df
}

# Check log sizes
nlogs-size() {
    echo -e "${BLUE}Checking log file sizes...${NC}"
    echo ""

    local services=("zookeeper" "kafka" "redis" "mongo" "emqx" "nexora-backend" "nexora-bff" "mqtt-handler" "nexora-ui" "nexora-nginx")

    for service in "${services[@]}"; do
        local container_id=$(docker ps -q -f "name=$service" 2>/dev/null)
        if [ -n "$container_id" ]; then
            local log_path=$(docker inspect --format='{{.LogPath}}' "$container_id" 2>/dev/null)
            if [ -f "$log_path" ]; then
                local size=$(du -h "$log_path" | cut -f1)
                printf "%-20s: %s\n" "$service" "$size"
            fi
        fi
    done
}

# View volume logs
nlogs-volume() {
    local vol=$1
    case $vol in
        kafka)
            echo -e "${BLUE}Kafka log files:${NC}"
            docker exec -it kafka sh -c "ls -lah /var/log/kafka 2>/dev/null" || echo "Cannot access Kafka logs"
            ;;
        mongo)
            echo -e "${BLUE}MongoDB log files:${NC}"
            docker exec -it mongo sh -c "ls -lah /var/log/mongodb 2>/dev/null" || echo "Cannot access MongoDB logs"
            ;;
        emqx)
            echo -e "${BLUE}EMQX log files:${NC}"
            docker exec -it emqx sh -c "ls -lah /opt/emqx/log 2>/dev/null" || echo "Cannot access EMQX logs"
            ;;
        *)
            echo -e "${YELLOW}Usage: nlogs-volume <kafka|mongo|emqx>${NC}"
            echo "Example: nlogs-volume kafka"
            return 1
            ;;
    esac
}

# Quick restart
nrestart() {
    local service=$1
    if [ -z "$service" ]; then
        echo -e "${YELLOW}Usage: nrestart <service-name>${NC}"
        echo "Example: nrestart kafka"
        echo ""
        echo -e "${BLUE}Available services:${NC}"
        docker-compose ps --services
        return 1
    fi
    echo -e "${BLUE}Restarting $service...${NC}"
    docker-compose restart "$service"
    echo -e "${GREEN}$service restarted${NC}"
}

# Show available commands
nlogs-help() {
    echo ""
    echo -e "${GREEN}=== Nexora Quick Log Commands ===${NC}"
    echo ""
    echo -e "${BLUE}View Logs:${NC}"
    echo "  nlogs                    - View all service logs"
    echo "  nlogsf                   - Follow all service logs"
    echo "  logs-<service>           - Follow specific service logs"
    echo "  logs-<service>-tail      - Tail last 100 lines of service logs"
    echo ""
    echo -e "${BLUE}Available Services:${NC}"
    echo "  zk, kafka, redis, mongo, emqx, backend, bff, mqtt, ui, nginx"
    echo ""
    echo -e "${BLUE}Search & Filter:${NC}"
    echo "  nlogs-errors <service>              - Search for errors"
    echo "  nlogs-search <service> <pattern>    - Search for pattern"
    echo "  nlogs-since <service> <time>        - View logs since time"
    echo ""
    echo -e "${BLUE}Export & Monitor:${NC}"
    echo "  nlogs-export <service>   - Export logs to file"
    echo "  nlogs-size               - Check log file sizes"
    echo "  nlogs-volume <service>   - View volume logs"
    echo ""
    echo -e "${BLUE}System:${NC}"
    echo "  nstatus                  - Check service status"
    echo "  nstats                   - Check resource usage"
    echo "  ndisk                    - Check disk usage"
    echo "  nrestart <service>       - Restart a service"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  logs-kafka              # View Kafka logs"
    echo "  nlogs-errors mongo      # Search MongoDB errors"
    echo "  nlogs-since redis 1h    # View Redis logs from last hour"
    echo "  nlogs-export backend    # Export backend logs to file"
    echo ""
    echo -e "${GREEN}For full log management tool, run: ./log-manager.sh${NC}"
    echo ""
}

# Print welcome message when sourced
echo -e "${GREEN}Nexora log commands loaded!${NC}"
echo -e "Type ${BLUE}nlogs-help${NC} to see available commands"
