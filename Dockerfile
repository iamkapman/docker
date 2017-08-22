FROM ubuntu:16.04

# Update & install soft
RUN \
    apt-get update && \
    apt-get upgrade -y
RUN apt-get install -y \
    git git-core nano screen curl unzip locales \
    php php-cli php-common php-intl php-json php-mysql php-gd php-imagick php-curl php-mcrypt php-mbstring php-dev php-xdebug

# PHP
#RUN sed -i -e "s/short_open_tag = Off/short_open_tag = On/g" /etc/php/7.0/fpm/php.ini
#RUN sed -i -e "s/post_max_size = 8M/post_max_size = 20M/g" /etc/php/7.0/fpm/php.ini
#RUN sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 20M/g" /etc/php/7.0/fpm/php.ini
#RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.0/fpm/php.ini
RUN rm /etc/php/7.0/fpm/php.ini
COPY docker/php.ini /etc/php/7.0/fpm/php.ini
COPY docker/20-xdebug.ini /etc/php/7.0/fpm/conf.d/

# MySQL
# https://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
RUN apt-get install -y mysql-server mysql-client

# NGINX
RUN \
    wget http://nginx.org/keys/nginx_signing.key && \
    apt-key add nginx_signing.key && \
    echo "deb http://nginx.org/packages/ubuntu/ codename nginx" >> /etc/apt/sources.list && \
    echo "deb-src http://nginx.org/packages/ubuntu/ codename nginx" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install nginx
#COPY conf/website /etc/nginx/sites-available/website
#RUN ln -s /etc/nginx/sites-available/website /etc/nginx/sites-enabled/website
#RUN rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

# SSH
RUN apt-get install -y openssh-server openssh-client
RUN mkdir /var/run/sshd
# Change password
RUN echo 'root:passwd' | chpasswd
#RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/bin/composer

#Add colorful command line
#RUN \
#    echo "force_color_prompt=yes" >> .bashrc && \
#    echo "export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]'" >> .bashrc

# Locale
RUN locale-gen en_US.UTF-8

# Supervisor
RUN \
    apt-get install -y supervisor && \
    mkdir -p /var/log/supervisor
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#open ports
EXPOSE 80 22 9000

CMD ["/usr/bin/supervisord", "-n"]
