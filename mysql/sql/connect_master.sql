CHANGE MASTER TO
MASTER_HOST='mysql-master',
MASTER_USER='slave',
MASTER_PASSWORD='slave@1024',
MASTER_LOG_FILE='binlog.000003',
MASTER_LOG_POS=769;

START SLAVE;
SHOW SLAVE STATUS\G