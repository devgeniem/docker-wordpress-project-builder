FROM devgeniem/wordpress-server:debian-php7.0
MAINTAINER Onni Hakala - Geniem Oy. <onni.hakala@geniem.com>

# Don't run services from this container
ENTRYPOINT []

RUN \
       apt-get update \
    # Install openssh to clone git packages
    && apt-get install ssh \

    # Install codesniffer with WordPress coding standards
    && composer create-project wp-coding-standards/wpcs --no-dev /opt/wpcs \

    # Install phpunit
    && composer global require phpunit/phpunit \

    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/log/apt/* /var/log/*.log

# Add phpunit and php codesniffer to path
ENV PATH ~/.composer/vendor/bin:/opt/wpcs/vendor/bin/:$PATH
