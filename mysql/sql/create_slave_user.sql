CREATE USER 'slave'@'%' IDENTIFIED BY 'slave@1024';
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'slave' @'%';
FLUSH PRIVILEGES;

select user,host from mysql.user where user='slave'\G
SHOW GRANTS FOR 'slave'@'%';

SHOW MASTER STATUS\G

