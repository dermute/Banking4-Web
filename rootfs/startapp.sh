#!/bin/sh

# jlesage/baseimage-gui runs this script as the container application user.
# The Wine prefix lives in /config so the Banking4 database and settings remain
# intact when the image is replaced.
set -eu

export WINEPREFIX="${BANKING4_WINEPREFIX:-/config/wine}"
export WINEARCH="${WINEARCH:-win32}"

app_path='C:\\Program Files\\TopBanking4\\TopBanking.exe'
app_file="${WINEPREFIX}/drive_c/Program Files/TopBanking4/TopBanking.exe"
marker_file="${WINEPREFIX}/.banking4-installer-id"
required_id="${BANKING4_INSTALLER_ID:-unknown}"

mkdir -p "${WINEPREFIX}"

if [ ! -f "${WINEPREFIX}/system.reg" ]; then
    echo "Initializing persistent Wine prefix at ${WINEPREFIX}."
    wineboot --init
fi

# Wine Mono implements the .NET runtime required by Banking4.  The MSI install
# is idempotent and registers it with this persistent Wine prefix.
wine msiexec /i "${BANKING4_WINE_MONO}" /qn

# Send Banking4's HTTP and HTTPS links to the stateless browser wrapper.
wine reg add 'HKCU\Software\Wine\WineBrowser' /v Browsers /t REG_SZ /d '/usr/local/bin/banking4-browser' /f

installed_id=""
if [ -f "${marker_file}" ]; then
    installed_id="$(cat "${marker_file}")"
fi

if [ ! -f "${app_file}" ] || [ "${installed_id}" != "${required_id}" ]; then
    if [ -f "${app_file}" ]; then
        echo "A newer Banking4 installer is available. Complete the upgrade wizard in the browser."
    else
        echo "Banking4 is not installed yet. Complete the setup wizard in the browser."
    fi

    wine "${BANKING4_INSTALLER}"

    if [ ! -f "${app_file}" ]; then
        echo "The Banking4 setup did not create ${app_path}. Complete the setup wizard and try again." >&2
        exit 1
    fi

    printf '%s\n' "${required_id}" > "${marker_file}"
fi

exec wine "${app_path}"

