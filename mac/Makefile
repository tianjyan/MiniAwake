APP_NAME = MiniAwake
SWIFT_FILES = main.swift
ICO_FILES   = ../Assets/disabled.ico ../Assets/timed.ico ../Assets/indefinite.ico
APP_BUNDLE  = $(APP_NAME).app
ICNS_FILE   = AppIcon.icns
ICONSET_DIR = AppIcon.iconset
BINARY      = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
BIN_X86     = .build/$(APP_NAME)_x86_64
BIN_ARM     = .build/$(APP_NAME)_arm64
SWIFT_OPTS  = -framework Cocoa -framework IOKit -O -whole-module-optimization
DBG_OPTS    = -framework Cocoa -framework IOKit -g -Onone

.PHONY: all clean run debug

all: $(APP_BUNDLE)

$(ICNS_FILE): ../Assets/disabled.ico create_icns.swift
	@swift create_icns.swift ../Assets/disabled.ico $(ICONSET_DIR)
	@iconutil -c icns $(ICONSET_DIR) -o $(ICNS_FILE)
	@rm -rf $(ICONSET_DIR)
	@echo "Generated $(ICNS_FILE)"

$(BIN_X86): $(SWIFT_FILES) $(ICO_FILES)
	@mkdir -p .build
	swiftc $(SWIFT_OPTS) -target x86_64-apple-macos11.0 -o $@ $(SWIFT_FILES)

$(BIN_ARM): $(SWIFT_FILES) $(ICO_FILES)
	@mkdir -p .build
	swiftc $(SWIFT_OPTS) -target arm64-apple-macos11.0 -o $@ $(SWIFT_FILES)

$(APP_BUNDLE): $(BINARY)

$(BINARY): $(BIN_X86) $(BIN_ARM) Info.plist $(ICNS_FILE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	lipo -create $(BIN_X86) $(BIN_ARM) -output $@
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp $(ICO_FILES) $(APP_BUNDLE)/Contents/Resources/
	@cp $(ICNS_FILE) $(APP_BUNDLE)/Contents/Resources/
	@echo "Built universal $(APP_BUNDLE)"

debug: $(SWIFT_FILES) $(ICO_FILES) Info.plist $(ICNS_FILE)
	@mkdir -p .build $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	swiftc $(DBG_OPTS) -target x86_64-apple-macos11.0 -o $(BIN_X86) $(SWIFT_FILES) || true
	swiftc $(DBG_OPTS) -target arm64-apple-macos11.0 -o $(BIN_ARM) $(SWIFT_FILES) || true
	if [ -f $(BIN_X86) ] && [ -f $(BIN_ARM) ]; then \
		lipo -create $(BIN_X86) $(BIN_ARM) -output $(BINARY); \
		echo "Built universal (debug)"; \
	elif [ -f $(BIN_X86) ]; then \
		cp $(BIN_X86) $(BINARY); \
		echo "Built x86_64 only (debug, cross-compile for arm64 failed)"; \
	elif [ -f $(BIN_ARM) ]; then \
		cp $(BIN_ARM) $(BINARY); \
		echo "Built arm64 only (debug, cross-compile for x86_64 failed)"; \
	else \
		echo "Build failed"; exit 1; \
	fi
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp $(ICO_FILES) $(APP_BUNDLE)/Contents/Resources/
	@cp $(ICNS_FILE) $(APP_BUNDLE)/Contents/Resources/

clean:
	rm -rf $(APP_BUNDLE) .build $(ICONSET_DIR) $(ICNS_FILE)

run: $(APP_BUNDLE)
	open $(APP_BUNDLE)
