#!/bin/bash
echo "Creating backup of n8n data..."
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
docker-compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/postgres_backup.sql"
echo "Backup created in: $BACKUP_DIR"
