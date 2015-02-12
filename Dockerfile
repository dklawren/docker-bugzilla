FROM centos:centos7
MAINTAINER David Lawrence <dkl@mozilla.com>

ADD CLOBBER /CLOBBER

# Environment configuration
ENV container docker
ENV BUGS_DB_DRIVER mysql
ENV BUGS_DB_NAME bugs
ENV BUGS_DB_PASS bugs
ENV BUGS_DB_HOST localhost
ENV BUGZILLA_USER bugzilla
ENV BUGZILLA_REPO https://git.mozilla.org/bugzilla/bugzilla.git
ENV BUGZILLA_REPO_BRANCH 4.4
ENV BUGZILLA_QA_REPO https://git.mozilla.org/bugzilla/qa.git
ENV BUGZILLA_QA_BRANCH 4.4
ENV BUGZILLA_HOME /home/$BUGZILLA_USER/devel/htdocs/bugzilla
ENV BUGZILLA_URL http://localhost/bugzilla
ENV ADMIN_EMAIL admin@
ENV ADMIN_PASS password
ENV TEST_SUITE sanity
ENV CPANM cpanm --quiet --notest --skip-satisfied

# Software installation
ADD rpm_list /rpm_list
RUN yum -y -q install epel-release \
    && yum clean all
RUN yum -y -q install `cat /rpm_list` && yum clean all

# User configuration
RUN useradd -m -G wheel -u 1000 -s /bin/bash $BUGZILLA_USER
RUN passwd -u -f $BUGZILLA_USER
RUN echo "bugzilla:bugzilla" | chpasswd

# sshd
RUN mkdir -p /var/run/sshd; chmod -rx /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
RUN sed -ri 's/#UseDNS yes/UseDNS no/'g /etc/ssh/sshd_config

# Apache configuration
ADD bugzilla.conf /etc/httpd/conf.d/bugzilla.conf

# Database configuration
ENV PGDATA /var/lib/pgsql/data
ENV PGPORT 5432
RUN su postgres -c "initdb"
RUN echo "host all all 0.0.0.0/0 trust" >> /var/lib/pgsql/data/pg_hba.conf
RUN echo "listen_addresses='*'" >> /var/lib/pgsql/data/postgresql.conf

# Sudoer configuration
ADD sudoers /etc/sudoers
RUN chown root.root /etc/sudoers; chmod 440 /etc/sudoers

# Clone the code repo
RUN su $BUGZILLA_USER -c "git clone $BUGZILLA_REPO -b $BUGZILLA_REPO_BRANCH $BUGZILLA_HOME"

# Install Perl dependencies
# Some modules are explicitly installed due to strange dependency issues
RUN cd $BUGZILLA_HOME \
    && $CPANM autodie \
    && $CPANM Apache2::SizeLimit \
    && $CPANM DBD::Pg \
    && $CPANM Email::Sender \
    && $CPANM File::Copy::Recursive \
    && $CPANM File::Which \
    && $CPANM HTML::FormatText \
    && $CPANM HTML::FormatText::WithLinks \
    && $CPANM HTML::TreeBuilder \
    && $CPANM Net::SMTP::SSL \
    && $CPANM Pod::Checker \
    && $CPANM Software::License \
    && $CPANM Test::WWW::Selenium \
    && $CPANM Text::Markdown \
    && $CPANM --installdeps --with-recommends .

# Bugzilla configuration
ADD checksetup_answers.txt /checksetup_answers.txt
ADD bugzilla_config.sh /bugzilla_config.sh
RUN chmod 755 /bugzilla_config.sh
RUN /bugzilla_config.sh

# Final permissions fix
RUN chmod 711 /home/$BUGZILLA_USER
RUN chown -R $BUGZILLA_USER.$BUGZILLA_USER /home/$BUGZILLA_USER

# Run any custom configuration
ADD my_config.sh /my_config.sh
RUN chmod 755 /my_config.sh
RUN /my_config.sh

# Networking
RUN echo "NETWORKING=yes" > /etc/sysconfig/network
EXPOSE 80
EXPOSE 22

# Testing script for CI
ADD runtests.sh /runtests.sh
RUN chmod 755 /runtests.sh

# Supervisor
ADD supervisord.conf /etc/supervisord.conf
RUN chmod 700 /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
