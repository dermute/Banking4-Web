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

Create a `.env` file from the example and set a unique browser password:

```sh
cp .env.example .env
# Edit BANKING4_IMAGE, WEB_AUTHENTICATION_USERNAME, and WEB_AUTHENTICATION_PASSWORD.
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
  ghcr.io/<owner>/banking4-web:latest
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

## License

The container scripts and configuration in this repository are under the
[MIT License](LICENSE). That license does not apply to Banking4 or its
installer, which are supplied by Subsembly under their own terms.
