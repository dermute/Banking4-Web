# Banking4-Web
#
# The Banking4 installer is downloaded unmodified from Subsembly during the
# image build.  The persistent Wine prefix is deliberately kept under /config.

ARG BASEIMAGE_VERSION=ubuntu-24.04-v4
ARG WINE_MONO_VERSION=11.2.0

FROM --platform=${BUILDPLATFORM} debian:bookworm-slim AS installer

ARG BANKING4_INSTALLER_URL=https://subsembly.com/download/TopBanking4Setup.exe
# This is a cache key supplied by CI from the HTTP response headers.
ARG BANKING4_INSTALLER_ID=unknown
ARG WINE_MONO_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Downloading Banking4 installer: ${BANKING4_INSTALLER_ID}" \
    && curl --fail --location --retry 3 --output /TopBanking4Setup.exe "${BANKING4_INSTALLER_URL}"

RUN curl --fail --location --retry 3 \
    --output /wine-mono.msi \
    "https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}-x86.msi"

FROM jlesage/baseimage-gui:${BASEIMAGE_VERSION}

ARG BANKING4_INSTALLER_ID=unknown
ARG DOCKER_IMAGE_VERSION=

USER 0

# Banking4's current installer is a 32-bit Windows executable.  Enable i386
# before installing Wine so both 32-bit and 64-bit Wine applications work.
RUN if ! getent passwd root >/dev/null; then printf "root:x:0:0:root:/root:/bin/sh\n" >> /etc/passwd; fi \
    && if ! getent group staff >/dev/null; then printf "staff:x:50:\n" >> /etc/group; fi \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cabextract \
        fonts-dejavu-core \
        fonts-liberation \
        wine \
        wine32 \
        wine64 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=installer /TopBanking4Setup.exe /opt/banking4/TopBanking4Setup.exe
COPY --from=installer /wine-mono.msi /opt/banking4/wine-mono.msi
COPY rootfs/ /

# APP_VERSION must not use the installer HTTP ETag: it may contain double quotes
# and break the base image's JSON web-data response.
RUN chmod 755 /startapp.sh /etc/cont-init.d/40-validate-web-auth \
    && set-cont-env APP_NAME "Banking4" \
    && set-cont-env APP_VERSION "TopBanking4" \
    && set-cont-env DOCKER_IMAGE_VERSION "${DOCKER_IMAGE_VERSION}" \
    && set-cont-env DISABLE_GLX 1

ENV \
    BANKING4_INSTALLER=/opt/banking4/TopBanking4Setup.exe \
    BANKING4_INSTALLER_ID=${BANKING4_INSTALLER_ID} \
    BANKING4_WINE_MONO=/opt/banking4/wine-mono.msi \
    BANKING4_WINEPREFIX=/config/wine \
    KEEP_APP_RUNNING=1 \
    SECURE_CONNECTION=1 \
    WEB_AUTHENTICATION=1 \
    WINEARCH=win32 \
    WINEDEBUG=-all

VOLUME ["/config"]

EXPOSE 5800 5900

LABEL \
    io.github.banking4-web.installer-id="${BANKING4_INSTALLER_ID}" \
    org.opencontainers.image.title="Banking4-Web" \
    org.opencontainers.image.description="Banking4 in a browser-accessible Wine container" \
    org.opencontainers.image.version="${DOCKER_IMAGE_VERSION}" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.vendor="Independent community project"

