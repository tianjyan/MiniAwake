APP_NAME = MiniAwake
SWIFT_FILES = main.swift
ICO_FILES   = ../Assets/disabled.ico ../Assets/timed.ico ../Assets/indefinite.ico
APP_BUNDLE  = $(APP_NAME).app
ICNS_FILE   = AppIcon.icns
ICONSET_DIR = AppIcon.iconset

.PHONY: all clean run debug

all: $(APP_BUNDLE)

$(ICNS_FILE): ../Assets/disabled.ico create_icns.swift
	@swift create_icns.swift ../Assets/disabled.ico $(ICONSET_DIR)
	@iconutil -c icns $(ICONSET_DIR) -o $(ICNS_FILE)
	@rm -rf $(ICONSET_DIR)
	@echo "Generated $(ICNS_FILE)"

$(APP_BUNDLE): $(SWIFT_FILES) $(ICO_FILES) Info.plist $(ICNS_FILE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	swiftc -framework Cocoa -framework IOKit \
		-O -whole-module-optimization \
		-o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) \
		$(SWIFT_FILES)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp $(ICO_FILES) $(APP_BUNDLE)/Contents/Resources/
	@cp $(ICNS_FILE) $(APP_BUNDLE)/Contents/Resources/
	@echo "Built $(APP_BUNDLE)"

debug: $(SWIFT_FILES) $(ICO_FILES) Info.plist $(ICNS_FILE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	swiftc -framework Cocoa -framework IOKit \
		-g -Onone \
		-o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) \
		$(SWIFT_FILES)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@cp $(ICO_FILES) $(APP_BUNDLE)/Contents/Resources/
	@cp $(ICNS_FILE) $(APP_BUNDLE)/Contents/Resources/
	@echo "Built $(APP_BUNDLE) (debug)"

clean:
	rm -rf $(APP_BUNDLE) $(ICONSET_DIR) $(ICNS_FILE)

run: $(APP_BUNDLE)
	open $(APP_BUNDLE)
