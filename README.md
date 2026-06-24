# Factory Droid Desktop for Linux

Build Factory Droid Desktop packages for multiple Linux distributions.

Factory Droid Desktop is the official Electron-based desktop application for [Factory](https://factory.ai) - an AI software engineering agent. This project provides Docker-based build scripts to package it for Fedora, Debian/Ubuntu, Arch Linux, and as a universal AppImage.

## Supported Distributions

| Distribution | Package Format | Build Command |
|---|---|---|
| Fedora 43+ | `.rpm` | `make rpm` |
| Debian 12+ / Ubuntu 24.04+ | `.deb` | `make deb` |
| Arch Linux | `.pkg.tar.zst` | `make arch` |
| Any Linux (universal) | `.AppImage` | `make appimage` |

## Quick Start

The `app.asar` file is already included in this repo (`build-linux/input/app.asar`).

```bash
# Build all packages (rpm + deb + arch)
make all

# Or build a specific package
make rpm      # Fedora RPM
make deb      # Debian/Ubuntu DEB
make arch     # Arch Linux package
make appimage # Universal AppImage
```

Output packages are placed in `build-linux/output/<format>/`.

## Install

### Fedora
```bash
sudo dnf install ./build-linux/output/rpm/factory-desktop-*.rpm
```

### Debian / Ubuntu
```bash
sudo apt install ./build-linux/output/deb/factory-desktop_*.deb
```

### Arch Linux
```bash
sudo pacman -U ./build-linux/output/arch/factory-desktop-*.pkg.tar.zst
```

### AppImage
```bash
chmod +x ./build-linux/output/appimage/Factory-Desktop-*.AppImage
./build-linux/output/appimage/Factory-Desktop-*.AppImage
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

The build system uses Docker containers for each target distribution:

1. Downloads Electron for Linux via npm
2. Downloads the Droid CLI binary from Factory's CDN
3. Copies the app.asar (cross-platform Electron app)
4. Creates desktop integration files (.desktop, icons, launcher)
5. Packages everything using `fpm` (or `linuxdeploy` for AppImage)

### Architecture Support

Set `TARGET_ARCH` to build for different architectures:

```bash
docker run --rm \
  -v "$(pwd)/build-linux/input:/build/input" \
  -v "$(pwd)/build-linux/output/deb:/output" \
  -e PACKAGE_TYPE=deb \
  -e TARGET_ARCH=arm64 \
  factory-desktop-builder:debian
```

Supported: `x86_64` (default), `arm64`

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

## Project Structure

```
build-linux/
├── Dockerfile.fedora        # Fedora build image
├── Dockerfile.debian        # Debian/Ubuntu build image
├── Dockerfile.arch          # Arch Linux build image
├── Dockerfile.appimage      # AppImage build image (CentOS 7 base)
├── build.sh                 # Parameterized build script
├── postinst.sh              # Distro-aware post-install hook
├── deps/
│   ├── fedora.txt           # RPM dependency list
│   ├── debian.txt           # DEB dependency list
│   └── arch.txt             # Pacman dependency list
├── scripts/
│   ├── download-electron.sh
│   ├── download-droid.sh
│   ├── install-app-asar.sh
│   └── create-desktop-files.sh
├── input/
│   └── app.asar
└── output/
    ├── rpm/
    ├── deb/
    ├── arch/
    └── appimage/
```

## License

This project provides build tooling only. Factory Desktop and Droid CLI are proprietary software by The San Francisco AI Factory, Inc. See [factory.ai](https://factory.ai) for terms.
