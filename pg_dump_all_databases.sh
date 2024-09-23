#!/bin/bash

# Настройки
PG_USER="postgres"                # Пользователь PostgreSQL
PG_HOST="localhost"               # Хост PostgreSQL (локальный)
PG_PORT="5432"                    # Порт PostgreSQL (обычно 5432)
BACKUP_DIR="/backup/location"     # Директория для хранения резервных копий
LOG_FILE="/var/log/pg_dump_backup.log" # Путь к лог-файлу
RETENTION_DAYS=7                  # Количество дней для хранения резервных копий

# Логирование
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "=== Начало резервного копирования всех баз данных PostgreSQL ==="

# Шаг 1: Получаем список всех баз данных
DATABASES=$(psql -U $PG_USER -h $PG_HOST -p $PG_PORT -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

# Шаг 2: Проверяем наличие директории для резервных копий
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Создание директории для резервных копий: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
fi

# Шаг 3: Создание резервных копий для каждой базы данных
for DB in $DATABASES; do
  BACKUP_NAME="${DB}_backup_$(date +%Y%m%d_%H%M%S).sql.gz"
  echo "Создание резервной копии базы данных: $DB"
  pg_dump -U $PG_USER -h $PG_HOST -p $PG_PORT $DB | gzip > $BACKUP_DIR/$BACKUP_NAME
  if [ $? -ne 0 ]; then
    echo "Ошибка при создании резервной копии базы данных: $DB"
    exit 1
  fi
  echo "Резервная копия для базы данных $DB создана: $BACKUP_DIR/$BACKUP_NAME"
done

# Шаг 4: Очистка старых резервных копий
echo "Очистка резервных копий старше $RETENTION_DAYS дней..."
find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \;
if [ $? -ne 0 ]; then
  echo "Ошибка при удалении старых резервных копий!"
  exit 1
fi

echo "Очистка старых резервных копий завершена."

echo "=== Резервное копирование всех баз данных завершено ==="

