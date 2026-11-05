# Omnisonic - Cross-platform build Makefile
# Requires: Flutter SDK in PATH

APP_NAME := omnisonic
VERSION := $(shell grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)
BUILD_NUMBER := $(shell grep '^version:' pubspec.yaml | cut -d'+' -f2)
BUILD_DIR := build
DIST_DIR := dist

# Android signing configuration
# Set these via environment variables or a local .env file
KEYSTORE ?= android/keystore.jks
KEY_ALIAS ?= omnisonic
KEYSTORE_PASS ?=
KEY_PASS ?= $(KEYSTORE_PASS)
APK_OUT := $(BUILD_DIR)/app/outputs/flutter-apk/app-release.apk

# Default target
.PHONY: help
help: ## Show this help
	@echo "Omnisonic v$(VERSION) - Build targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── Setup & Dependencies ────────────────────────────────────────────────────

.PHONY: setup
setup: ## Install dependencies and run code generation
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs

.PHONY: deps
deps: ## Install dependencies only
	flutter pub get

.PHONY: codegen
codegen: ## Run code generation (build_runner)
	dart run build_runner build --delete-conflicting-outputs

.PHONY: codegen-watch
codegen-watch: ## Run code generation in watch mode
	dart run build_runner watch --delete-conflicting-outputs

# ─── Analysis & Testing ──────────────────────────────────────────────────────

.PHONY: analyze
analyze: ## Run static analysis
	flutter analyze

.PHONY: test
test: ## Run all tests
	flutter test

.PHONY: format
format: ## Format all Dart files
	dart format lib/ test/

.PHONY: check
check: format analyze test ## Format, analyze, and test

# ─── Android ─────────────────────────────────────────────────────────────────

.PHONY: apk
apk: ## Build Android APK (release, signed)
	flutter build apk --release
	@if [ -f "$(KEYSTORE)" ] && [ -n "$(KEYSTORE_PASS)" ]; then \
		echo "Signing APK with $(KEYSTORE)..."; \
		apksigner sign \
			--ks "$(KEYSTORE)" \
			--ks-key-alias "$(KEY_ALIAS)" \
			--ks-pass "pass:$(KEYSTORE_PASS)" \
			--key-pass "pass:$(KEY_PASS)" \
			"$(APK_OUT)"; \
		echo "Verifying signature..."; \
		apksigner verify "$(APK_OUT)"; \
	else \
		echo "Note: APK signed with debug key (set KEYSTORE + KEYSTORE_PASS for release signing)"; \
	fi

.PHONY: apk-debug
apk-debug: ## Build Android APK (debug)
	flutter build apk --debug

.PHONY: appbundle
appbundle: ## Build Android App Bundle (release, for Play Store)
	flutter build appbundle --release

.PHONY: apk-split
apk-split: ## Build split APKs per ABI (release, signed)
	flutter build apk --release --split-per-abi
	@if [ -f "$(KEYSTORE)" ] && [ -n "$(KEYSTORE_PASS)" ]; then \
		echo "Signing split APKs with $(KEYSTORE)..."; \
		for apk in $(BUILD_DIR)/app/outputs/flutter-apk/app-*-release.apk; do \
			apksigner sign \
				--ks "$(KEYSTORE)" \
				--ks-key-alias "$(KEY_ALIAS)" \
				--ks-pass "pass:$(KEYSTORE_PASS)" \
				--key-pass "pass:$(KEY_PASS)" \
				"$$apk"; \
		done; \
		echo "All split APKs signed."; \
	else \
		echo "Note: APKs signed with debug key (set KEYSTORE + KEYSTORE_PASS for release signing)"; \
	fi

.PHONY: run-android
run-android: ## Run on connected Android device
	flutter run -d android

.PHONY: keystore
keystore: ## Generate a release keystore (interactive)
	@if [ -f "$(KEYSTORE)" ]; then \
		echo "Keystore already exists: $(KEYSTORE)"; \
		exit 1; \
	fi
	keytool -genkey -v \
		-keystore "$(KEYSTORE)" \
		-alias "$(KEY_ALIAS)" \
		-keyalg RSA -keysize 2048 -validity 10000
	@echo ""
	@echo "Keystore created: $(KEYSTORE)"
	@echo "Use it with: make apk KEYSTORE=$(KEYSTORE) KEY_ALIAS=$(KEY_ALIAS) KEYSTORE_PASS=<password>"

# ─── iOS ─────────────────────────────────────────────────────────────────────

.PHONY: ipa
ipa: ## Build iOS IPA (release, requires macOS + signing)
	flutter build ipa --release

.PHONY: ios
ios: ## Build iOS app (release)
	flutter build ios --release

.PHONY: run-ios
run-ios: ## Run on iOS simulator
	flutter run -d ios

# ─── Linux ───────────────────────────────────────────────────────────────────

.PHONY: linux
linux: ## Build Linux executable (release)
	flutter build linux --release

.PHONY: linux-debug
linux-debug: ## Build Linux executable (debug)
	flutter build linux --debug

.PHONY: run-linux
run-linux: ## Run Linux build directly
	flutter run -d linux

.PHONY: linux-bundle
linux-bundle: linux ## Build Linux and copy bundle to dist/
	@mkdir -p $(DIST_DIR)
	@rm -rf $(DIST_DIR)/$(APP_NAME)-linux-x64
	cp -r $(BUILD_DIR)/linux/x64/release/bundle $(DIST_DIR)/$(APP_NAME)-linux-x64
	@echo "Linux bundle: $(DIST_DIR)/$(APP_NAME)-linux-x64/"

.PHONY: linux-tar
linux-tar: linux-bundle ## Package Linux build as .tar.gz
	cd $(DIST_DIR) && tar -czf $(APP_NAME)-$(VERSION)-linux-x64.tar.gz $(APP_NAME)-linux-x64/
	@echo "Archive: $(DIST_DIR)/$(APP_NAME)-$(VERSION)-linux-x64.tar.gz"

# ─── macOS ───────────────────────────────────────────────────────────────────

.PHONY: macos
macos: ## Build macOS application (release)
	flutter build macos --release

.PHONY: macos-debug
macos-debug: ## Build macOS application (debug)
	flutter build macos --debug

.PHONY: run-macos
run-macos: ## Run on macOS
	flutter run -d macos

.PHONY: macos-bundle
macos-bundle: macos ## Build macOS and copy .app to dist/
	@mkdir -p $(DIST_DIR)
	@rm -rf $(DIST_DIR)/$(APP_NAME)-macos
	mkdir -p $(DIST_DIR)/$(APP_NAME)-macos
	cp -r $(BUILD_DIR)/macos/Build/Products/Release/$(APP_NAME).app $(DIST_DIR)/$(APP_NAME)-macos/
	@echo "macOS app: $(DIST_DIR)/$(APP_NAME)-macos/$(APP_NAME).app"

.PHONY: macos-dmg
macos-dmg: macos-bundle ## Package macOS build as .dmg (requires create-dmg)
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-size 600 400 \
		--app-drop-link 400 200 \
		"$(DIST_DIR)/$(APP_NAME)-$(VERSION)-macos.dmg" \
		"$(DIST_DIR)/$(APP_NAME)-macos/"
	@echo "DMG: $(DIST_DIR)/$(APP_NAME)-$(VERSION)-macos.dmg"

# ─── Windows ─────────────────────────────────────────────────────────────────

.PHONY: windows
windows: ## Build Windows executable (release)
	flutter build windows --release

.PHONY: windows-debug
windows-debug: ## Build Windows executable (debug)
	flutter build windows --debug

.PHONY: run-windows
run-windows: ## Run on Windows
	flutter run -d windows

.PHONY: windows-bundle
windows-bundle: windows ## Build Windows and copy bundle to dist/
	@mkdir -p $(DIST_DIR)
	@rm -rf $(DIST_DIR)/$(APP_NAME)-windows-x64
	cp -r $(BUILD_DIR)/windows/x64/runner/Release $(DIST_DIR)/$(APP_NAME)-windows-x64
	@echo "Windows bundle: $(DIST_DIR)/$(APP_NAME)-windows-x64/"

.PHONY: windows-zip
windows-zip: windows-bundle ## Package Windows build as .zip
	cd $(DIST_DIR) && zip -r $(APP_NAME)-$(VERSION)-windows-x64.zip $(APP_NAME)-windows-x64/
	@echo "Archive: $(DIST_DIR)/$(APP_NAME)-$(VERSION)-windows-x64.zip"

# ─── All Platforms ───────────────────────────────────────────────────────────

.PHONY: all-desktop
all-desktop: linux macos windows ## Build all desktop platforms

.PHONY: all-mobile
all-mobile: apk ipa ## Build all mobile platforms (APK + IPA)

.PHONY: all
all: all-desktop all-mobile ## Build everything

.PHONY: dist-all
dist-all: linux-tar macos-bundle windows-zip ## Package all platforms for distribution

# ─── Icons ───────────────────────────────────────────────────────────────────

.PHONY: icons
icons: ## Generate launcher icons for all platforms
	dart run flutter_launcher_icons

# ─── Cleanup ─────────────────────────────────────────────────────────────────

.PHONY: clean
clean: ## Clean Flutter build artifacts
	flutter clean

.PHONY: clean-dist
clean-dist: ## Remove dist/ directory
	rm -rf $(DIST_DIR)

.PHONY: clean-all
clean-all: clean clean-dist ## Clean everything (build + dist)

# ─── Doctor & Info ───────────────────────────────────────────────────────────

.PHONY: doctor
doctor: ## Run flutter doctor
	flutter doctor -v

.PHONY: devices
devices: ## List available devices
	flutter devices

.PHONY: info
info: ## Show project info
	@echo "App:     $(APP_NAME)"
	@echo "Version: $(VERSION)+$(BUILD_NUMBER)"
	@flutter --version | head -1
