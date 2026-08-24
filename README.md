# Banking4-Web

Run the Windows desktop application [Banking4](https://banking4.de/) in a
Docker container and use it through an HTML5 browser window.  The image uses
[Wine](https://www.winehq.org/) on Ubuntu and
[jlesage/baseimage-gui](https://github.com/jlesage/docker-baseimage-gui) for
the virtual desktop, noVNC, and process supervision.

> [!WARNING]
> Banking4 contains financial information and bank credentials.  Browser
> authentication is mandatory in this image. Use a long unique password, do
> not expose port 5800 directly to the internet, and use HTTPS through a
> reverse proxy or a VPN for any remote access.

> [!IMPORTANT]
> This is an independent, unofficial packaging project. It is not affiliated
> with, endorsed by, sponsored by, or supported by Subsembly, Banking4, or
> jlesage. Banking4 and its installer remain the property of Subsembly; you
> are responsible for complying with their license terms.

## Quick start

Set a unique browser-login password directly in `docker-compose.yml`, then start
the container:

```sh
# Edit WEB_AUTHENTICATION_USERNAME and WEB_AUTHENTICATION_PASSWORD first.
docker compose up -d
```

Open `https://localhost:5800` and sign in using the credentials in `.env`.
The first window is the official Banking4 installation wizard. Complete it in
the browser; the container then starts Banking4 automatically. The installer
is interactive because Subsembly does not publish a confirmed unattended
installation mode.

To use the image without Compose, replace `<owner>` and choose strong
credentials:

```sh
docker run -d \
  --name banking4-web \
  --restart unless-stopped \
  -p 5800:5800 \
  -v /docker/appdata/banking4:/config \
  -e WEB_AUTHENTICATION_USERNAME=banking4 \
  -e WEB_AUTHENTICATION_PASSWORD='use-a-long-unique-password' \
  ghcr.io/dermute/banking4-web:latest
```

## Data and updates

All persistent state, including the Wine prefix and Banking4 data, is in
`/config` (or `./config` with Compose). Treat it as sensitive and back it up
securely. Do not attach the same directory to more than one running container.

The GitHub Actions workflow checks daily for both the official installer and
the `linux/amd64` manifest of `jlesage/baseimage-gui:ubuntu-24.04-v4`. It
publishes a new GHCR image only when one of those inputs changes. Each image
records both input identities as OCI labels.

After an update:

```sh
docker compose pull
docker compose up -d
```

If the bundled Banking4 installer changed, the next browser session displays
the official upgrade wizard. Complete it to retain the existing Wine prefix
and continue with the new application version.

## Configuration

| Setting | Required/default | Purpose |
| --- | --- | --- |
| `WEB_AUTHENTICATION_USERNAME` | Required | Browser-login username. |
| `WEB_AUTHENTICATION_PASSWORD` | Required | Browser-login password. |
| `TZ` | `Etc/UTC` | Time zone shown by the application. |
| `USER_ID` / `GROUP_ID` | `1000` | Ownership of files written to `/config`. |
| `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` | `1920` / `1080` | Virtual desktop size. |
| `VNC_PASSWORD` | unset | Optional native-VNC password if port 5900 is published. |
| `SECURE_CONNECTION` | `1` | Enable the base image's built-in HTTPS support when certificates are configured. |

`WEB_AUTHENTICATION` cannot be disabled. For remote use, terminate TLS at a
trusted reverse proxy or configure the base image's secure-connection support.
Do not store passwords in a committed `.env` file; use your deployment
platform's secrets facility where possible.

## Cloud authentication browser

Banking4 opens cloud-authentication links with [GNOME Web (Epiphany)](https://apps.gnome.org/Epiphany/), a WebKit browser chosen instead of a full Chromium-based browser.

Each authentication window receives a new private Epiphany profile under `/tmp`.
WebKit's internal process sandbox is disabled only for this browser process.
This is necessary on Docker hosts that prohibit the user namespaces required by
Epiphany's nested sandbox. The browser still runs inside the container, but it
is not a general-purpose browsing environment; access the container only through
the authenticated HTTPS interface or a trusted VPN.
Its profile, cookies, history, cache, downloads, password store, and other site
data are deleted as soon as that browser window closes. They are never written to
`/config`; stale temporary browser directories are also removed whenever the
container starts.

This means browser login persistence is intentionally unsupported: authenticate
again when Banking4 needs a new cloud session.

## Build locally

```sh
docker build -t banking4-web .
```

The build downloads `TopBanking4Setup.exe` directly from Subsembly and includes
it unchanged. It targets `linux/amd64`: Banking4's installer is a 32-bit
Windows executable and runs through Wine.

## Troubleshooting

- **The container immediately exits:** provide both required browser-auth
  variables and inspect `docker logs banking4-web`.
- **The wizard appears again after an update:** finish the wizard rather than
  closing it. The container records the bundled installer identity only after
  the expected Banking4 executable exists.
- **The UI is blank or Wine exits:** inspect `docker logs banking4-web`; Wine
  compatibility can vary by Banking4 release. Keep a backup of `/config`
  before trying a new image.
- **Resetting Banking4:** stop the container and remove only its chosen
  `/config` directory or Docker volume. This deletes Banking4 data and
  credentials, so make a verified backup first.

## AI attribution

This project was developed with AI assistance.

<div style="display: flex; align-items: center; white-space: nowrap; gap: 0.5rem; padding: 8px;">
  <div style="font-family: IBM Plex Sans; font-weight: 400; font-size: 16px; line-height: 22px; letter-spacing: 0px;">
    <a rel="noopener noreferrer" href="https://aiattribution.github.io/statements/AIA-EAI-Hin-Nr-?model=GPT%252D5.6-v1.0" data-cy="recommended-attribution-statement-text" target="_blank" style="font-family: IBM Plex Sans; font-weight: 400; font-size: 16px; line-height: 22px; letter-spacing: 0px;">AIA EAI Hin Nr GPT-5.6 v1.0 </a>
  </div>
  <div style="display: flex; gap: 0.5rem;">
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <g clip-path="url(#clip0_50_2)">
        <path d="M12 23.5C18.3513 23.5 23.5 18.3513 23.5 12C23.5 5.64873 18.3513 0.5 12 0.5C5.64873 0.5 0.5 5.64873 0.5 12C0.5 18.3513 5.64873 23.5 12 23.5Z" fill="#4E4E4E" stroke="#161616">
        </path>
        <path d="M13.6471 15.6L13.1471 13.94H10.8171L10.3171 15.6H8.77715L11.0771 8.61998H12.9571L15.2271 15.6H13.6471ZM11.9971 9.99998H11.9471L11.1771 12.65H12.7771L11.9971 9.99998Z" fill="white">
        </path>
      </g>
      <defs>
        <clipPath id="clip0_50_2">
          <rect width="24" height="24" fill="white">
          </rect>
        </clipPath>
      </defs>
    </svg>
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M18 17H16.5V16H18V8H16.5V7H18C18.2651 7.0003 18.5193 7.10576 18.7068 7.29323C18.8942 7.4807 18.9997 7.73488 19 8V16C18.9996 16.2651 18.8942 16.5193 18.7067 16.7067C18.5193 16.8942 18.2651 16.9996 18 17Z" fill="#161616">
      </path>
      <path d="M15.5 13C16.0523 13 16.5 12.5523 16.5 12C16.5 11.4477 16.0523 11 15.5 11C14.9477 11 14.5 11.4477 14.5 12C14.5 12.5523 14.9477 13 15.5 13Z" fill="#161616">
      </path>
      <path d="M12 13C12.5523 13 13 12.5523 13 12C13 11.4477 12.5523 11 12 11C11.4477 11 11 11.4477 11 12C11 12.5523 11.4477 13 12 13Z" fill="#161616">
      </path>
      <path d="M8.5 13C9.05228 13 9.5 12.5523 9.5 12C9.5 11.4477 9.05228 11 8.5 11C7.94772 11 7.5 11.4477 7.5 12C7.5 12.5523 7.94772 13 8.5 13Z" fill="#161616">
      </path>
      <path d="M7.5 17H6C5.73488 16.9997 5.4807 16.8942 5.29323 16.7068C5.10576 16.5193 5.0003 16.2651 5 16V8C5.00026 7.73486 5.10571 7.48066 5.29319 7.29319C5.48066 7.10571 5.73486 7.00026 6 7H7.5V8H6V16H7.5V17Z" fill="#161616">
      </path>
      <circle cx="12" cy="12" r="11.5" stroke="#161616">
      </circle>
      <circle cx="12" cy="12" r="11.5" stroke="#161616">
      </circle>
    </svg>
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="12" cy="12" r="11.5" stroke="#161616">
      </circle>
      <path d="M10 6C10.4945 6 10.9778 6.14662 11.3889 6.42133C11.8 6.69603 12.1205 7.08648 12.3097 7.54329C12.4989 8.00011 12.5484 8.50277 12.452 8.98773C12.3555 9.47268 12.1174 9.91814 11.7678 10.2678C11.4181 10.6174 10.9727 10.8555 10.4877 10.952C10.0028 11.0484 9.50011 10.9989 9.04329 10.8097C8.58648 10.6205 8.19603 10.3 7.92133 9.88893C7.64662 9.4778 7.5 8.99445 7.5 8.5C7.5 7.83696 7.76339 7.20107 8.23223 6.73223C8.70107 6.26339 9.33696 6 10 6ZM10 5C9.30777 5 8.63108 5.20527 8.0555 5.58986C7.47993 5.97444 7.03133 6.52107 6.76642 7.16061C6.50151 7.80015 6.4322 8.50388 6.56725 9.18282C6.7023 9.86175 7.03564 10.4854 7.52513 10.9749C8.01461 11.4644 8.63825 11.7977 9.31718 11.9327C9.99612 12.0678 10.6999 11.9985 11.3394 11.7336C11.9789 11.4687 12.5256 11.0201 12.9101 10.4445C13.2947 9.86892 13.5 9.19223 13.5 8.5C13.5 7.57174 13.1313 6.6815 12.4749 6.02513C11.8185 5.36875 10.9283 5 10 5Z" fill="#161616">
      </path>
      <path d="M15 19H14V16.5C14 15.837 13.7366 15.2011 13.2678 14.7322C12.7989 14.2634 12.163 14 11.5 14H8.5C7.83696 14 7.20107 14.2634 6.73223 14.7322C6.26339 15.2011 6 15.837 6 16.5V19H5V16.5C5 15.5717 5.36875 14.6815 6.02513 14.0251C6.6815 13.3687 7.57174 13 8.5 13H11.5C12.4283 13 13.3185 13.3687 13.9749 14.0251C14.6313 14.6815 15 15.5717 15 16.5V19Z" fill="#161616">
      </path>
      <path d="M19.9592 9.99025L19.3932 9.42432L17.938 10.8796L16.4827 9.42432L15.9167 9.99025L17.372 11.4455L15.9167 12.9008L16.4827 13.4667L17.938 12.0115L19.3932 13.4667L19.9592 12.9008L18.5039 11.4455L19.9592 9.99025Z" fill="#161616">
      </path>
    </svg>
  </div>
</div>

## License

The container scripts and configuration in this repository are under the
[MIT License](LICENSE). That license does not apply to Banking4 or its
installer, which are supplied by Subsembly under their own terms.
