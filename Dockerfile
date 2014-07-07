FROM fedora
MAINTAINER David Lawrence <dkl@mozilla.com>

# Environment
ENV container docker
ENV BUGZILLA_USER bugzilla
ENV BUGZILLA_REPO https://github.com/bugzilla/bugzilla.git
ENV BUGZILLA_BRANCH 4.4

# Software installation
RUN yum -y install https://dev.mysql.com/get/mysql-community-release-fc20-5.noarch.rpm; yum clean all
RUN yum -y install supervisor mod_perl openssh-server mysql-community-server git \
                   sudo perl-App-cpanminus perl-CPAN mysql-community-devel \
                   gcc gcc-c++ make vim-enhanced perl-Software-License gd-devel \
                   openssl-devel ImageMagick-devel graphviz patch; yum clean all
RUN yum -y update; yum clean all

# User configuration
RUN useradd -m -G wheel -u 1000 -s /bin/bash $BUGZILLA_USER
RUN passwd -u -f $BUGZILLA_USER
RUN echo "bugzilla:bugzilla" | chpasswd
RUN mkdir -p /home/$BUGZILLA_USER/devel/htdocs

# sshd
RUN mkdir -p /var/run/sshd; chmod -rx /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
RUN sed -ri 's/#UseDNS yes/UseDNS no/'g /etc/ssh/sshd_config

# Apache configuration
ADD bugzilla.conf /etc/httpd/conf.d/bugzilla.conf

# MySQL configuration
ADD my.cnf /etc/my.cnf
RUN chmod 644 /etc/my.cnf; chown root.root /etc/my.cnf
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

# Supervisor
ADD supervisord.conf /etc/supervisord.conf
RUN chmod 700 /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "--configuration", "/etc/supervisord.conf"]
