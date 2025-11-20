# SPDX-FileCopyrightText: © 2025 Nfrastack <code@nfrastack.com>
#
# SPDX-License-Identifier: MIT

ARG \
    BASE_IMAGE

FROM ${BASE_IMAGE}

LABEL \
        org.opencontainers.image.title="Nextcloud" \
        org.opencontainers.image.description="Groupware Platform" \
        org.opencontainers.image.url="https://hub.docker.com/r/nfrastack/nextcloud" \
        org.opencontainers.image.documentation="https://github.com/nfrastack/container-nextcloud/blob/main/README.md" \
        org.opencontainers.image.source="https://github.com/nfrastack/container-nextcloud.git" \
        org.opencontainers.image.authors="Nfrastack <code@nfrastack.com>" \
        org.opencontainers.image.vendor="Nfrastack <https://www.nfrastack.com>" \
        org.opencontainers.image.licenses="MIT"

ARG \
    NEXTCLOUD_VERSION="32.0.2" \
    NEXTCLOUD_FILES_BACKEND_VERSION="v1.2.0" \
    NEXTCLOUD_FILES_BACKEND_REPO_URL="https://github.com/nextcloud/notify_push" \
    DLIB_VERSION="v20.0" \
    DLIB_REPO_URL="https://github.com/davisking/dlib" \
    PDLIB_VERSION="v1.1.0" \
    PDLIB_REPO_URL="https://github.com/goodspb/pdlib"

COPY CHANGELOG.md /usr/src/container/CHANGELOG.md
COPY LICENSE /usr/src/container/LICENSE
COPY README.md /usr/src/container/README.md

ENV \
    CONTAINER_ENABLE_SCHEDULING=TRUE \
    NGINX_SITE_ENABLED=nextcloud \
    NGINX_WEBROOT="/www/nextcloud" \
    NGINX_HEADER01_NAME="Referrer-Policy" \
    NGINX_HEADER01_VALUE="no-referrer" \
    NGINX_HEADER01_FLAG="always" \
    NGINX_HEADER02_NAME="X-Content-Type-Options" \
    NGINX_HEADER02_VALUE="nosniff" \
    NGINX_HEADER02_FLAG="always" \
    NGINX_HEADER03_NAME="X-Frame-Options" \
    NGINX_HEADER03_VALUE="SAMEORIGIN" \
    NGINX_HEADER03_FLAG="always" \
    NGINX_HEADER04_NAME="X-Permitted-Cross-Domain-Policies" \
    NGINX_HEADER04_VALUE="none" \
    NGINX_HEADER04_FLAG="always" \
    NGINX_HEADER05_NAME="X-Robots-Tag" \
    NGINX_HEADER05_VALUE="noindex, nofollow" \
    NGINX_HEADER05_FLAG="always" \
    PHP_ENABLE_CREATE_SAMPLE_PHP=FALSE \
    PHP_MODULE_ENABLE_BCMATH=TRUE \
    PHP_MODULE_ENABLE_EXIF=TRUE \
    PHP_MODULE_ENABLE_FILEINFO=TRUE \
    PHP_MODULE_ENABLE_FTP=TRUE \
    PHP_MODULE_ENABLE_GMP=TRUE \
    PHP_MODULE_ENABLE_IMAGICK=TRUE \
    PHP_MODULE_ENABLE_IGBINARY=TRUE \
    PHP_MODULE_ENABLE_LDAP=TRUE \
    PHP_MODULE_ENABLE_MSGPACK=TRUE \
    PHP_MODULE_ENABLE_PCNTL=TRUE \
    PHP_MODULE_ENABLE_PDLIB=TRUE \
    PHP_MODULE_ENABLE_PDO=TRUE \
    PHP_MODULE_ENABLE_PDO_SQLITE=TRUE \
    PHP_MODULE_ENABLE_PDO_PGSQL=TRUE \
    PHP_MODULE_ENABLE_POSIX=TRUE \
    PHP_MODULE_ENABLE_PGSQL=TRUE \
    PHP_MODULE_ENABLE_REDIS=TRUE \
    PHP_MODULE_ENABLE_SIMPLEXML=TRUE \
    PHP_MODULE_ENABLE_SODIUM=TRUE \
    PHP_MODULE_ENABLE_SQLITE3=TRUE \
    PHP_MODULE_ENABLE_SYSVSEM=TRUE \
    PHP_MODULE_ENABLE_XMLWRITER=TRUE \
    PHP_MODULE_ENABLE_ZIP=TRUE \
    PHP_MEMORY_LIMIT="512M" \
    PHP_TIMEOUT=600 \
    IMAGE_NAME="nfrastack/nextcloud" \
    IMAGE_REPO_URL="https://github.com/nfrastack/container-nextcloud/"

RUN echo "" && \
    DLIB_BUILD_DEPS_ALPINE=" \
                                build-base \
                                cmake \
                                ffmpeg-dev \
                                git \
                                libjpeg-turbo-dev \
                                libjxl-dev \
                                libpng-dev \
                                libx11-dev \
                                openblas-dev \
                                samurai \
                            " \
                            && \
    PDLIB_BUILD_DEPS_ALPINE=" \
                                php$(php-ext info base_alt)-dev \
                            " \
                            && \
    NEXTCLOUD_RUN_DEPS_ALPINE=" \
                                c-client \
                                coreutils \
                                ffmpeg \
                                findutils \
                                freetype \
                                gd \
                                ghostscript \
                                gmp \
                                icu \
                                imagemagick-jxl \
                                imagemagick-heic \
                                libedit \
                                libmcrypt \
                                libreoffice \
                                libsmbclient \
                                libwebp \
                                libxml2 \
                                libzip \
                                ocrmypdf \
                                openblas \
                                openldap-clients \
                                openssl \
                                p7zip \
                                pcre \
                                rsync \
                                samba-client \
                                sqlite \
                                zlib \
                              " \
                              && \
    \
    source /container/base/functions/container/build && \
    container_build_log image && \
    package update && \
    package upgrade && \
    package install \
                        DLIB_BUILD_DEPS \
                        NEXTCLOUD_RUN_DEPS \
                        PDLIB_BUILD_DEPS \
                    && \
    \
    clone_git_repo "${DLIB_REPO_URL}" "${DLIB_VERSION}" && \
    cmake \
            -B build \
            -G Ninja \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DBUILD_SHARED_LIBS=ON \
            -DCMAKE_BUILD_TYPE=None \
            && \
    cmake --build build && \
    cmake --install build && \
    container_build_log add "Dlib" "${DLIB_VERSION}" "${DLIB_REPO_URL}" && \
    \
    clone_git_repo ${PDLIB_REPO_URL} "${PDLIB_VERSION}" && \
    phpize${PHP_BASE/./} && \
    ./configure \
                --prefix=/usr \
                --with-php-config=php-config$(php-ext info base_alt) \
                && \
    make -j $(nproc) && \
    make install && \
    echo "extension=pdlib" > "$(php-ext info modules_path)"/pdlib.ini && \
    echo ";priority=20" >> "$(php-ext info modules_path)"/pdlib.ini && \
    container_build_log add "Pdlib" "${PDLIB_VERSION}" "${PDLIB_REPO_URL}" && \
    \
    php-ext prepare && \
    php-ext reset && \
    php-ext enable core && \
    \
    mkdir -p /container/data/nextcloud/install/custom-apps && \
    if [[ "${NEXTCLOUD_VERSION}" =~ beta|pre|rc ]]; then \
        nrp=prer ; \
    else \
        nrp=r ; \
    fi ; \
    curl -sSL https://download.nextcloud.com/server/${nrp}eleases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2 | tar xvfj - --strip 1 -C /container/data/nextcloud/install && \
    chown -R "${NGINX_USER}":"${NGINX_GROUP}" /container/data/nextcloud/install && \
    container_build_log add "Nextcloud" "${NEXTCLOUD_VERSION}" "${NEXTCLOUD_REPO_URL}" && \
    \
    mkdir -p /opt/notify_push/bin/ && \
    chown -R "${NGINX_USER}":"${NGINX_GROUP}" /opt/notify_push && \
    curl -sSL "${NEXTCLOUD_FILES_BACKEND_REPO_URL}"/releases/download/${NEXTCLOUD_FILES_BACKEND_VERSION}/notify_push-$(container_info arch)-unknown-linux-musl -o /opt/notify_push/bin/notify_push && \
    chmod +x /opt/notify_push/bin/notify_push && \
    container_build_log add "Notify Push" "${NEXTCLOUD_FILES_BACKEND_VERSION}" "${NEXTCLOUD_FILES_BACKEND_REPO_URL}" && \
    \
    package remove \
                    DLIB_BUILD_DEPS \
                    PDLIB_BUILD_DEPS \
                    && \
    package cleanup

COPY rootfs /
