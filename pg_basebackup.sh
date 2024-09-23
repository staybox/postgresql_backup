#!/bin/bash

# Настройки
PG_USER="postgres"                # Пользователь PostgreSQL
PG_HOST="localhost"               # Хост PostgreSQL (локальный)
PG_PORT="5432"                    # Порт PostgreSQL (обычно 5432)
BACKUP_DIR="/backup/location"     # Директория для хранения резервных копий
BACKUP_NAME="pgsql_backup_$(date +%Y%m%d_%H%M%S)"  # Имя резервной копии с меткой времени
LOG_FILE="/var/log/pg_backup.log" # Путь к лог-файлу
RETENTION_DAYS=7                  # Количество дней для хранения резервных копий

# Логирование
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "=== Начало резервного копирования PostgreSQL ==="

# Шаг 1: Проверяем наличие директории для резервных копий
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Создание директории для резервных копий: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
fi

# Шаг 2: Запуск физического резервного копирования с использованием pg_basebackup
echo "Создание резервной копии базы данных..."
pg_basebackup -h $PG_HOST -p $PG_PORT -U $PG_USER -D $BACKUP_DIR/$BACKUP_NAME -Ft -z -Xf -P
if [ $? -ne 0 ]; then
  echo "Ошибка при создании резервной копии!"
  exit 1
fi

echo "Резервная копия успешно создана в: $BACKUP_DIR/$BACKUP_NAME"

# Шаг 3: Очистка старых резервных копий
echo "Очистка резервных копий старше $RETENTION_DAYS дней..."
find $BACKUP_DIR -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;
if [ $? -ne 0 ]; then
  echo "Ошибка при удалении старых резервных копий!"
  exit 1
fi

echo "Очистка старых резервных копий завершена."

echo "=== Резервное копирование завершено ==="

