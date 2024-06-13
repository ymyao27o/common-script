## 概述
1. 该脚本以mysql主从结构的demo的docker-compose脚本，使用setup -i 即可执行脚本和相关配置
2. 容器版本使用mysql:5.7.16
3. 预设mysql配置文件，master节点将会输出general、error、slow、binlog 日志，slave节点仅设置只读和中继日志
4. 容器日志目录和数据目录预设在相同位置挂载在自动分配至volume中，详细需要位置使用inspect查看
5. 位置存放不分开原因为，修改log输出目录后会出现无创建权限的问题，导致mysqld启动失败，解决方式可能以该镜像为基类重新包装或者其他？
