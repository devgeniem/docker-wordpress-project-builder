FROM alpine:3.4
MAINTAINER Onni Hakala - Geniem Oy. <onni.hakala@geniem.com>

RUN cd /tmp/ && \

    # Install curl first and dustinblackman/phantomized package
    # This is because if alpine packages share something with dustinblackman/phantomized we can replace those
    apk --update add curl && \

    ##
    # PhantomJS
    ##
    # Install phantomjs dependencies
    curl -L "https://github.com/dustinblackman/phantomized/releases/download/2.1.1/dockerized-phantomjs.tar.gz" \
    | tar xz -C / && \

    # Install phantomjs binary
    curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
    | tar -xjC /tmp && \
    mv /tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/ && \
    chmod +rx /usr/local/bin/phantomjs && \

    # Install dependencies and small amount of devtools
    apk add bash less vim nano git mysql-client ca-certificates openssh-client \
    # Libs for php
    libssh2 libpng freetype libjpeg-turbo libgcc libxml2 libstdc++ icu-libs libltdl libmcrypt \
    # Set timezone according your location
    tzdata && \
    # Upgrade musl
    apk add -u musl && \

    ##
    # Install php7
    # - These repositories are in 'testing' repositories but it's much more stable/easier than compiling our own php.
    ##
    apk add --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/testing/ \
    php7-pdo_mysql php7-mysqli php7-mysqlnd php7-mcrypt \
    php7 php7-session php7-fpm php7-json php7-zlib php7-xml php7-pdo \
    php7-gd php7-curl php7-opcache php7-ctype php7-mbstring php7-soap \
    php7-intl php7-bcmath php7-dom php7-xmlreader php7-openssl php7-phar php7-redis  && \

    # Small fixes to php & nginx
    ln -s /etc/php7 /etc/php && \
    ln -s /usr/bin/php7 /usr/bin/php && \
    ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm && \
    ln -s /usr/lib/php7 /usr/lib/php && \

    ##
    # Install wp-cli
    # source: http://wp-cli.org/
    ##
    curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp-cli && \
    chmod +rx /usr/local/bin/wp-cli && \

    ##
    # Install composer
    # source: https://getcomposer.org/download/
    ##
    curl -L https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php && \
    rm  composer-setup.php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +rx /usr/local/bin/composer && \

    ##
    # Add WP coding standards with php codesniffer
    ##
    composer create-project wp-coding-standards/wpcs:dev-master --no-interaction --no-dev /var/lib/wpcs && \

    ##
    # Install ruby + dependencies and integration testing tools
    # - We install build libraries only for this one run so whole image can stay smaller size
    ##
    apk --update add ruby libxslt && \
    apk add --virtual build_deps build-base ruby-dev libc-dev linux-headers \
    openssl-dev postgresql-dev libxml2-dev libxslt-dev && \
    gem install json rspec rspec-retry poltergeist capybara --no-ri --no-rdoc && \
    apk del build_deps && \

    # Remove cache and tmp files
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

# Copy custom configs and scripts into container
COPY system-root/ /

# Create wordpress user and web group
# Ideally this would use same UID and GID as the user who runs the dev but this is better
# than using root user for wp-cli
RUN addgroup -g 101 web && \
    adduser -u 100 -G web -S -D wordpress

# Update path with composer files + wpcs
ENV TERM="xterm" \
    # Set defaults which can be overriden
    DB_PORT="3306" \
    # Set defaults for redis
    WP_REDIS_PORT="6379" \
    WP_REDIS_DATABASE="0" \
    WP_REDIS_SCHEME="tcp" \
    WP_REDIS_CLIENT="pecl" \
    # Cronlock is used to stop simultaneous cronjobs in clusterised environments
    CRONLOCK_HOST="" \
    # This is for your project root
    PROJECT_ROOT="/var/www/project"\
    # This is used by nginx and php-fpm
    WEB_ROOT="/var/www/project/web"\
    # This is used automatically by wp-cli
    WP_CORE="/var/www/project/web/wp"\
    # This folder is used to mount files into host machine
    # You should use this path for your uploads since everything else should be ephemeral
    UPLOADS_ROOT="/var/www/uploads"\
    # This can be overidden by you, it's just default for us
    TZ="Europe/Helsinki"

# Mount projects in here and run commands here too
WORKDIR /var/www/project
