# Factory Droid Desktop for Fedora Linux

Build Factory Droid Desktop as an RPM package for Fedora 43+ GNOME.

Factory Droid Desktop is the official Electron-based desktop application for [Factory](https://factory.ai) - an AI software engineering agent. This project provides Docker-based build scripts to package it for Fedora Linux.

## Prerequisites

- Docker
- The `app.asar` file from a Factory Desktop installation (place in `build-linux/input/app.asar`)

## Quick Start

```bash
# 1. Place app.asar in the input directory
cp /path/to/app.asar build-linux/input/app.asar

# 2. Build the Docker image
docker build -t factory-desktop-builder build-linux/

# 3. Build the RPM
docker run --rm \
  -v "$(pwd)/build-linux/input:/build/input" \
  -v "$(pwd)/build-linux/output-rpm:/output" \
  factory-desktop-builder
```

The RPM will be at `build-linux/output-rpm/factory-desktop-*.rpm`.

## Install on Fedora

```bash
sudo dnf install ./factory-desktop-0.114.1-1.fc43.x86_64.rpm
```

Then run `factory-desktop` from terminal or find "Factory" in your application menu.

## Package Contents

| Component | Location |
|---|---|
| Electron (v39.2.7) | `/opt/factory-desktop/factory-desktop` |
| Factory Desktop App | `/opt/factory-desktop/resources/app.asar` |
| Droid CLI (v0.157.1) | `/opt/factory-desktop/resources/bin/droid` |
| Desktop Entry | `/usr/share/applications/factory-desktop.desktop` |
| Launcher | `/usr/bin/factory-desktop` |

## How It Works

The build script (`build.sh`) runs inside a Fedora 43 Docker container and:

1. Downloads Electron for Linux via npm
2. Downloads the Droid CLI binary from Factory's CDN
3. Copies the app.asar (cross-platform Electron app)
4. Creates desktop integration files (.desktop, icons, launcher)
5. Packages everything as RPM using `fpm`

## License

This project provides build tooling only. Factory Desktop and Droid CLI are proprietary software by The San Francisco AI Factory, Inc. See [factory.ai](https://factory.ai) for terms.
