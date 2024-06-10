CREATE USER 'slave'@'%' IDENTIFIED BY 'slave@1024';
GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%';
FLUSH PRIVILEGES;

SHOW MASTER STATUS;
