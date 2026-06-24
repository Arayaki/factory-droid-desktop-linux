FROM fedora:43

RUN dnf install -y \
    nodejs \
    npm \
    ruby \
    ruby-devel \
    gcc \
    make \
    rpm-build \
    curl \
    git \
    desktop-file-utils \
    && dnf clean all

RUN gem install fpm

# Electron version matching the desktop app
ENV ELECTRON_VERSION=39.2.7
ENV DROID_CLI_VERSION=0.157.1

WORKDIR /build

COPY build.sh /build/build.sh
COPY postinst.sh /build/postinst.sh
RUN chmod +x /build/build.sh /build/postinst.sh

ENTRYPOINT ["/build/build.sh"]
