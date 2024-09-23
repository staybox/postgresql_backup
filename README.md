# postgresql_backup

Скрипты создают резервную копию данных PostgreSQL.

Скрипт pg_dump_all_databases.sh создает резервную копию всех баз данных на сервере с помощью pg_dump исключая шаблонные БД.

Скрипт pg_basebackup.sh создает физический бэкап всего кластера PostgreSQL с журналами WAL.
