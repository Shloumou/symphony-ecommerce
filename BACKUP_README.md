# MySQL Database Backup System

## Overview

The ecommerce application now has an **automated backup system** for the MySQL database using Kubernetes CronJob.

## Backup Configuration

- **Schedule**: Daily at 2:00 AM (configurable)
- **Location**: `/backups` directory inside the MySQL pod
- **Storage**: Persistent Volume (5GB)
- **Retention**: Last 30 days of backups
- **Format**: Compressed `.sql.gz` files
- **Naming**: `ecommerce_db_backup_YYYYMMDD_HHMMSS.sql.gz`

## Files Created

1. **k8s/mysql-backup-cronjob.yaml** - CronJob and PVC configuration
2. **backup-restore.sh** - Command-line utility for backup management

## Quick Start

### Check Backup Status

```bash
./backup-restore.sh info
```

### List All Backups

```bash
./backup-restore.sh list
```

### Create Manual Backup (Right Now)

```bash
./backup-restore.sh backup
```

### Restore Database from Backup

```bash
# List backups first
./backup-restore.sh list

# Restore from a specific backup
./backup-restore.sh restore ecommerce_db_backup_20251115_020000.sql.gz
```

### Download Backup to Local Machine

```bash
# Download to current directory
./backup-restore.sh download ecommerce_db_backup_20251115_020000.sql.gz

# Download to specific path
./backup-restore.sh download ecommerce_db_backup_20251115_020000.sql.gz /home/salem/backups/
```

## Where Backups Are Stored

### Inside Kubernetes Cluster

Backups are stored in a **Persistent Volume** mounted at:
```
/backups (inside the MySQL pod)
```

### Accessing Backups Directly

```bash
# List backups in Kubernetes
kubectl -n ecommerce exec deployment/mysql -- ls -lh /backups/

# Copy backup to your local machine
kubectl -n ecommerce cp mysql-<pod-name>:/backups/ecommerce_db_backup_20251115_020000.sql.gz ./
```

### PVC Details

```bash
# Check PVC status
kubectl -n ecommerce get pvc mysql-backup-pvc

# Check PVC size and usage
kubectl -n ecommerce describe pvc mysql-backup-pvc
```

## Manual Operations

### Run Backup Job Manually (Without Waiting for Schedule)

```bash
# Create a job from the CronJob
kubectl -n ecommerce create job manual-backup-$(date +%Y%m%d%H%M) --from=cronjob/mysql-backup

# Watch the job
kubectl -n ecommerce get jobs -w

# Check logs
kubectl -n ecommerce logs -l job-name=manual-backup-<timestamp>
```

### Check CronJob Status

```bash
# View CronJob details
kubectl -n ecommerce get cronjob mysql-backup

# Check last execution
kubectl -n ecommerce get jobs

# View CronJob logs from last run
kubectl -n ecommerce logs -l job-name=mysql-backup-<timestamp>
```

### Modify Backup Schedule

Edit the CronJob schedule:
```bash
kubectl -n ecommerce edit cronjob mysql-backup
```

Common cron schedules:
- `0 2 * * *` - Daily at 2:00 AM
- `0 */6 * * *` - Every 6 hours
- `0 0 * * 0` - Weekly (Sunday at midnight)
- `0 0 1 * *` - Monthly (1st day at midnight)
- `*/30 * * * *` - Every 30 minutes

## Restore Process (Detailed)

### Step 1: List Available Backups

```bash
./backup-restore.sh list
```

Output example:
```
-rw-r--r-- 1 999 999 2.3M Nov 15 02:00 ecommerce_db_backup_20251115_020000.sql.gz
-rw-r--r-- 1 999 999 2.3M Nov 14 02:00 ecommerce_db_backup_20251114_020000.sql.gz
```

### Step 2: Choose a Backup and Restore

```bash
./backup-restore.sh restore ecommerce_db_backup_20251115_020000.sql.gz
```

**WARNING**: This will overwrite the current database!

### Step 3: Restart Application (Optional)

```bash
kubectl -n ecommerce rollout restart deployment/ecommerce-app
```

## Backup to External Storage

### Option 1: Download All Backups

```bash
#!/bin/bash
mkdir -p ~/database-backups
cd ~/database-backups

# Get all backup files
kubectl -n ecommerce exec deployment/mysql -- ls /backups/ | while read backup; do
    kubectl -n ecommerce cp mysql-$(kubectl -n ecommerce get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}'):/backups/$backup ./$backup
    echo "Downloaded: $backup"
done
```

### Option 2: Sync to S3/Cloud Storage (Advanced)

You can modify the CronJob to include AWS CLI or rclone to sync backups to:
- AWS S3
- Google Cloud Storage
- Azure Blob Storage
- Any S3-compatible storage

## Troubleshooting

### No Backups Found

```bash
# Check if PVC is created
kubectl -n ecommerce get pvc mysql-backup-pvc

# Check if volume is mounted
kubectl -n ecommerce describe pod mysql-<pod-name> | grep -A 5 Mounts
```

### CronJob Not Running

```bash
# Check CronJob status
kubectl -n ecommerce describe cronjob mysql-backup

# Check if jobs are being created
kubectl -n ecommerce get jobs

# Manually trigger a job to test
kubectl -n ecommerce create job test-backup --from=cronjob/mysql-backup
kubectl -n ecommerce logs job/test-backup -f
```

### Restore Failed

```bash
# Check if backup file exists
kubectl -n ecommerce exec deployment/mysql -- ls -lh /backups/

# Test backup file integrity
kubectl -n ecommerce exec deployment/mysql -- gunzip -t /backups/your-backup.sql.gz

# Check MySQL pod logs
kubectl -n ecommerce logs deployment/mysql --tail=100
```

## Backup File Contents

Each backup includes:
- All database tables
- Stored procedures and functions
- Triggers
- Events
- Complete data

## Security Notes

✅ **Backups are stored on persistent volumes within the cluster**
✅ **Root password is stored in Kubernetes secrets**
✅ **Backups are compressed to save space**
⚠️ **For production, consider encrypting backups**
⚠️ **For critical data, sync backups to external/cloud storage**

## Monitoring

### Set Up Alerts (Optional)

You can monitor backup job failures:

```bash
# Check failed jobs
kubectl -n ecommerce get jobs --field-selector status.successful!=1

# Set up alerts (example using kubectl)
kubectl -n ecommerce get events --field-selector involvedObject.kind=CronJob,involvedObject.name=mysql-backup
```

## Backup Retention Policy

- **Automatic cleanup**: Backups older than 30 days are automatically deleted
- **Manual retention**: Download important backups to external storage before they expire
- **Modify retention**: Edit the CronJob script to change the 30-day limit

## Quick Reference

| Command | Description |
|---------|-------------|
| `./backup-restore.sh list` | List all backups |
| `./backup-restore.sh backup` | Create manual backup |
| `./backup-restore.sh restore <file>` | Restore from backup |
| `./backup-restore.sh download <file>` | Download backup locally |
| `./backup-restore.sh info` | Show configuration |

## Next Steps

1. ✅ Test the backup system: `./backup-restore.sh backup`
2. ✅ Verify backups are created: `./backup-restore.sh list`
3. ⚠️ Download important backups to external storage
4. 📅 Set up monitoring/alerts for backup failures
5. 🔐 Consider encrypting backups for production use

---

**Created**: November 15, 2025
**Location**: Kubernetes namespace `ecommerce`
**Contact**: Database Administrator
