# Jobe-in-a-box: a Dockerised Jobe server (see https://github.com/trampgeek/jobe)
# With thanks to David Bowes (d.h.bowes@lancaster.ac.uk) who did all the hard work
# on this originally.

FROM docker.io/ubuntu:22.04

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL \
    org.opencontainers.image.authors="richard.lobb@canterbury.ac.nz,j.hoedjes@hva.nl,d.h.bowes@herts.ac.uk" \
    org.opencontainers.image.title="JobeInABox" \
    org.opencontainers.image.description="JobeInABox" \
    org.opencontainers.image.documentation="https://github.com/trampgeek/jobeinabox" \
    org.opencontainers.image.source="https://github.com/trampgeek/jobeinabox"

ARG TZ=UTC
# Set up the (apache) environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV LANG C.UTF-8

# Copy apache virtual host file for later use
COPY 000-jobe.conf /

# Copy test script
COPY container-test.sh /

# Set timezone
# Install extra packages
# Redirect apache logs to stdout
# Configure apache
# Configure php
# Get and install jobe
# Clean up
RUN ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && \
    echo "$TZ" > /etc/timezone && \
    apt-get update && \
    apt-get --no-install-recommends install -yq \
        acl \
        apache2 \
        build-essential \
        libapache2-mod-php \
        openjdk-19-jdk \
        php \
        php-mbstring \
        python3 \
        python3-pip \
        python3-setuptools \
        sqlite3 \
        sudo \
        tzdata \
        unzip && \
    python3 -m pip install pylint && \
    pylint --reports=no --score=n --generate-rcfile > /etc/pylintrc && \
    ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log && \
    sed -i "s/export LANG=C/export LANG=$LANG/" /etc/apache2/envvars && \
    sed -i '1 i ServerName localhost' /etc/apache2/apache2.conf && \
    sed -i 's/ServerTokens\ OS/ServerTokens \Prod/g' /etc/apache2/conf-enabled/security.conf && \
    sed -i 's/ServerSignature\ On/ServerSignature \Off/g' /etc/apache2/conf-enabled/security.conf && \
    rm /etc/apache2/sites-enabled/000-default.conf && \
    mv /000-jobe.conf /etc/apache2/sites-enabled/ && \
    mkdir -p /var/crash && \
    chmod 777 /var/crash && \
    echo '<!DOCTYPE html><html lang="en"><title>Jobe</title><h1>Jobe</h1></html>' > /var/www/html/index.html

# Copy the source of jobe
COPY jobe/ /var/www/html/jobe/

# FIXME: maybe want to move the apt-get purge, etc. back into the previous layer.
RUN apache2ctl start && \
    cd /var/www/html/jobe && \
    /usr/bin/python3 /var/www/html/jobe/install --max_uid=500 && \
    chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/www/html && \
    apt-get purge -y build-essential && \
    apt-get -y autoremove --purge && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

# Add jar files to /usr/local/lib/java for use by Java jobs. Put this after the
# rest since we're more likely to want to change this part (by adding files)
# than some of the earlier layers.
RUN mkdir -p /usr/local/lib/java
COPY jars/* /usr/local/lib/java/
RUN chmod a+w /usr/local/lib/java

# Expose apache
EXPOSE 80

# Healthcheck, minimaltest.py should complete within 2 seconds
HEALTHCHECK --interval=5m --timeout=2s \
    CMD /usr/bin/python3 /var/www/html/jobe/minimaltest.py || exit 1

# Start apache
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
