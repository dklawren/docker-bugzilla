FROM fedora
MAINTAINER David Lawrence <dkl@mozilla.com>

# Environment
ENV container docker
ENV BUGZILLA_USER bugzilla
ENV BUGZILLA_REPO https://github.com/bugzilla/bugzilla.git
ENV BUGZILLA_BRANCH 4.4

# Software installation
RUN yum -y install https://dev.mysql.com/get/mysql-community-release-fc20-5.noarch.rpm
RUN yum -y install systemd mod_perl openssh-server mysql-community-server git \
                   sudo perl-App-cpanminus perl-CPAN mysql-community-devel \
                   gcc gcc-c++ make vim-enhanced perl-Software-License gd-devel \
                   openssl-devel ImageMagick-devel graphviz patch
RUN yum -y update
RUN yum clean all

# Systemd configuration
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;

# User configuration
RUN useradd -m -G wheel -u 1000 -s /bin/bash $BUGZILLA_USER
RUN passwd -u -f $BUGZILLA_USER
RUN echo "bugzilla:bugzilla" | chpasswd
RUN mkdir -p /home/$BUGZILLA_USER/devel/htdocs

# sshd
ADD ssh_config.sh /ssh_config.sh
RUN chmod 755 /ssh_config.sh
RUN /ssh_config.sh

# Apache configuration
ADD bugzilla.conf /etc/httpd/conf.d/bugzilla.conf
RUN systemctl enable httpd.service

# MySQL configuration
ADD my.cnf /etc/my.cnf
RUN chmod 644 /etc/my.cnf; chown root.root /etc/my.cnf
ADD mysqld.service /etc/systemd/system/mysqld.service
RUN chmod 644 /etc/systemd/system/mysqld.service
RUN systemctl enable mysqld.service
RUN rm -rf /etc/mysql
RUN rm -rf /var/lib/mysql/*
RUN /usr/bin/mysql_install_db --user=$BUGZILLA_USER --basedir=/usr --datadir=/var/lib/mysql

# Sudoer configuration
ADD sudoers /etc/sudoers
RUN chown root.root /etc/sudoers; chmod 440 /etc/sudoers

# Bugzilla configuration
ADD checksetup_answers.txt /checksetup_answers.txt
ADD bugzilla_config.sh /bugzilla_config.sh
RUN chmod 755 /bugzilla_config.sh
RUN /bugzilla_config.sh

# Final permissions fix
RUN chmod 711 /home/$BUGZILLA_USER
RUN chown -R $BUGZILLA_USER.$BUGZILLA_USER /home/$BUGZILLA_USER

# Networking
RUN echo "NETWORKING=yes" > /etc/sysconfig/network
EXPOSE 80
EXPOSE 22

VOLUME ["/sys/fs/cgroup"]

CMD ["/usr/sbin/init"]
