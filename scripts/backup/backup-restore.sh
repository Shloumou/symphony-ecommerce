#!/bin/bash
# Database Backup and Restore Script for Kubernetes

set -e

NAMESPACE="ecommerce"
BACKUP_PVC="mysql-backup-pvc"
MYSQL_POD=$(kubectl -n ${NAMESPACE} get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

echo -e "${GREEN}=== MySQL Database Backup & Restore Utility ===${NC}\n"

# Function to list backups
list_backups() {
    echo -e "${YELLOW}Available backups:${NC}"
    kubectl -n ${NAMESPACE} exec deployment/mysql -- ls -lh /backups/ 2>/dev/null || echo "No backups found or backup volume not mounted"
}

# Function to create manual backup
create_backup() {
    echo -e "${GREEN}Creating manual backup...${NC}"
    BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="ecommerce_db_backup_${BACKUP_DATE}.sql"
    
    kubectl -n ${NAMESPACE} exec deployment/mysql -- bash -c "
        mysqldump -uroot -pchangeme_root_password \
            --databases ecommerce_db \
            --single-transaction \
            --quick \
            --lock-tables=false \
            --routines \
            --triggers \
            --events \
            > /backups/${BACKUP_FILE} && \
        gzip /backups/${BACKUP_FILE} && \
        echo 'Backup created: /backups/${BACKUP_FILE}.gz' && \
        ls -lh /backups/${BACKUP_FILE}.gz
    "
    
    echo -e "${GREEN}Backup completed successfully!${NC}"
}

# Function to restore from backup
restore_backup() {
    local BACKUP_FILE=$1
    
    if [ -z "$BACKUP_FILE" ]; then
        echo -e "${RED}Error: Please provide backup filename${NC}"
        echo "Usage: $0 restore <backup_filename>"
        list_backups
        exit 1
    fi
    
    echo -e "${YELLOW}WARNING: This will restore the database from backup: ${BACKUP_FILE}${NC}"
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Restore cancelled."
        exit 0
    fi
    
    echo -e "${GREEN}Restoring database from ${BACKUP_FILE}...${NC}"
    
    # Check if file is gzipped
    if [[ $BACKUP_FILE == *.gz ]]; then
        kubectl -n ${NAMESPACE} exec deployment/mysql -- bash -c "
            gunzip -c /backups/${BACKUP_FILE} | mysql -uroot -pchangeme_root_password
        "
    else
        kubectl -n ${NAMESPACE} exec deployment/mysql -- bash -c "
            mysql -uroot -pchangeme_root_password < /backups/${BACKUP_FILE}
        "
    fi
    
    echo -e "${GREEN}Database restored successfully!${NC}"
}

# Function to download backup to local machine
download_backup() {
    local BACKUP_FILE=$1
    local LOCAL_PATH=${2:-./}
    
    if [ -z "$BACKUP_FILE" ]; then
        echo -e "${RED}Error: Please provide backup filename${NC}"
        echo "Usage: $0 download <backup_filename> [local_path]"
        list_backups
        exit 1
    fi
    
    echo -e "${GREEN}Downloading ${BACKUP_FILE} to ${LOCAL_PATH}...${NC}"
    kubectl -n ${NAMESPACE} cp ${MYSQL_POD}:/backups/${BACKUP_FILE} ${LOCAL_PATH}/${BACKUP_FILE}
    echo -e "${GREEN}Download completed: ${LOCAL_PATH}/${BACKUP_FILE}${NC}"
}

# Function to show backup volume info
show_info() {
    echo -e "${GREEN}Backup Configuration:${NC}"
    echo "Namespace: ${NAMESPACE}"
    echo "PVC Name: ${BACKUP_PVC}"
    echo "Backup Location: /backups (inside MySQL pod)"
    echo "Schedule: Daily at 2:00 AM"
    echo "Retention: 30 days"
    echo ""
    kubectl -n ${NAMESPACE} get pvc ${BACKUP_PVC} 2>/dev/null || echo "Backup PVC not yet created"
    echo ""
    kubectl -n ${NAMESPACE} get cronjob mysql-backup 2>/dev/null || echo "CronJob not yet deployed"
}

# Main script logic
case "${1:-help}" in
    list)
        list_backups
        ;;
    backup|create)
        create_backup
        ;;
    restore)
        restore_backup "$2"
        ;;
    download)
        download_backup "$2" "$3"
        ;;
    info)
        show_info
        ;;
    help|*)
        echo "Usage: $0 {list|backup|restore|download|info}"
        echo ""
        echo "Commands:"
        echo "  list                          - List all available backups"
        echo "  backup                        - Create a manual backup now"
        echo "  restore <backup_file>         - Restore database from a backup"
        echo "  download <backup_file> [path] - Download backup to local machine"
        echo "  info                          - Show backup configuration info"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 backup"
        echo "  $0 restore ecommerce_db_backup_20251115_140000.sql.gz"
        echo "  $0 download ecommerce_db_backup_20251115_140000.sql.gz /tmp/"
        ;;
esac
