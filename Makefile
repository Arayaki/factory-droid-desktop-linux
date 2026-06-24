.PHONY: rpm deb arch appimage all clean

INPUT_DIR  := $(CURDIR)/build-linux/input
OUTPUT_DIR := $(CURDIR)/build-linux/output

rpm:
	docker build -t factory-desktop-builder:fedora -f build-linux/Dockerfile.fedora build-linux/
	docker run --rm \
		-v "$(INPUT_DIR):/build/input" \
		-v "$(OUTPUT_DIR)/rpm:/output" \
		factory-desktop-builder:fedora

deb:
	docker build -t factory-desktop-builder:debian -f build-linux/Dockerfile.debian build-linux/
	docker run --rm \
		-v "$(INPUT_DIR):/build/input" \
		-v "$(OUTPUT_DIR)/deb:/output" \
		factory-desktop-builder:debian

arch:
	docker build -t factory-desktop-builder:arch -f build-linux/Dockerfile.arch build-linux/
	docker run --rm \
		-v "$(INPUT_DIR):/build/input" \
		-v "$(OUTPUT_DIR)/arch:/output" \
		factory-desktop-builder:arch

appimage:
	docker build -t factory-desktop-builder:appimage -f build-linux/Dockerfile.appimage build-linux/
	docker run --rm \
		-v "$(INPUT_DIR):/build/input" \
		-v "$(OUTPUT_DIR)/appimage:/output" \
		factory-desktop-builder:appimage

all: rpm deb arch

clean:
	rm -rf "$(OUTPUT_DIR)/rpm" "$(OUTPUT_DIR)/deb" "$(OUTPUT_DIR)/arch" "$(OUTPUT_DIR)/appimage"
