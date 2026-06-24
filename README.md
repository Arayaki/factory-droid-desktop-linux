# Factory Droid Desktop for Fedora Linux

Build Factory Droid Desktop as an RPM package for Fedora 43+ GNOME.

Factory Droid Desktop is the official Electron-based desktop application for [Factory](https://factory.ai) - an AI software engineering agent. This project provides Docker-based build scripts to package it for Fedora Linux.

## Quick Start

The `app.asar` file is already included in this repo (`build-linux/input/app.asar`).

```bash
# 1. Build the Docker image
docker build -t factory-desktop-builder build-linux/

# 2. Build the RPM
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

## How to Obtain app.asar

The `app.asar` is already included in this repo. If you need to obtain it yourself:

### Option A: From Windows Factory Desktop installation

1. Download and install Factory Desktop on Windows from [factory.ai](https://factory.ai)
2. Navigate to the installation directory (typically `%LOCALAPPDATA%\Factory\`)
3. Find `app.asar` inside the `resources` folder
4. Copy it to `build-linux/input/app.asar`

### Option B: From the Windows installer (.exe)

1. Download `Factory-0.114.1 Setup.exe` from [factory.ai](https://factory.ai)
2. Extract the installer with 7-Zip:
   ```bash
   7z x "Factory-0.114.1 Setup.exe"
   ```
3. Navigate to `Factory-0.114.1-full/lib/net45/resources/`
4. Copy `app.asar` to `build-linux/input/app.asar`

### Option C: From a NuGet package (.nupkg)

1. Download `Factory-0.114.1-full.nupkg` from Factory's releases
2. The `.nupkg` is a ZIP file - extract it:
   ```bash
   unzip Factory-0.114.1-full.nupkg -d factory-extracted
   ```
3. Navigate to `factory-extracted/lib/net45/resources/`
4. Copy `app.asar` to `build-linux/input/app.asar`

## License

This project provides build tooling only. Factory Desktop and Droid CLI are proprietary software by The San Francisco AI Factory, Inc. See [factory.ai](https://factory.ai) for terms.
