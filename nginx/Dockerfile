# 使用官方的 Ubuntu 镜像作为基础镜像
FROM nginx:latest

# 将当前目录下的文件复制到容器的/app目录下
COPY default.conf /etc/nginx/conf.d/
COPY cert /etc/nginx/cert

VOLUME ["/etc/nginx/conf.d", "/var/log/nginx", "/usr/share/nginx/html"]

# 暴露端口
EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]

CMD []
