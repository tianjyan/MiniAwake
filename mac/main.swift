import Cocoa
import IOKit.pwr_mgt

enum AwakeMode: Equatable {
    case none
    case min30
    case hour1
    case hour2
    case infinite
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    var statusItem: NSStatusItem!
    var mainMenu: NSMenu!
    var intervalSubMenu: NSMenu!

    var awakeMode: AwakeMode = .none
    var keepDisplayOn: Bool = false

    var systemAssertionID: IOPMAssertionID = 0
    var displayAssertionID: IOPMAssertionID = 0

    var endTime: Date?
    var tickTimer: Timer?
    var watchdogTimer: Timer?

    var iconDisabled: NSImage?
    var iconTimed: NSImage?
    var iconIndefinite: NSImage?

    private enum MenuTag: Int {
        case keep30m = 1
        case keep1h
        case keep2h
        case keepInfinite
        case stop
        case displayToggle
        case exit
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let barSize = NSSize(width: 18, height: 18)

        iconDisabled   = Bundle.main.image(forResource: "disabled")?.menuBarIcon(size: barSize)
        iconTimed      = Bundle.main.image(forResource: "timed")?.menuBarIcon(size: barSize)
        iconIndefinite = Bundle.main.image(forResource: "indefinite")?.menuBarIcon(size: barSize)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
        }
        updateIcon()
        buildMenu()
        updateMenuItems()
        startWatchdog()
    }

    func buildMenu() {
        mainMenu = NSMenu()
        mainMenu.autoenablesItems = false
        mainMenu.delegate = self

        intervalSubMenu = NSMenu()
        intervalSubMenu.autoenablesItems = false
        intervalSubMenu.delegate = self

        let item30m = NSMenuItem(title: "30 minutes", action: #selector(keep30m), keyEquivalent: "")
        item30m.target = self
        item30m.tag = MenuTag.keep30m.rawValue
        intervalSubMenu.addItem(item30m)

        let item1h = NSMenuItem(title: "1 hour", action: #selector(keep1h), keyEquivalent: "")
        item1h.target = self
        item1h.tag = MenuTag.keep1h.rawValue
        intervalSubMenu.addItem(item1h)

        let item2h = NSMenuItem(title: "2 hours", action: #selector(keep2h), keyEquivalent: "")
        item2h.target = self
        item2h.tag = MenuTag.keep2h.rawValue
        intervalSubMenu.addItem(item2h)

        let intervalItem = NSMenuItem()
        intervalItem.submenu = intervalSubMenu
        intervalItem.title = "Keep awake on interval"
        mainMenu.addItem(intervalItem)

        let infiniteItem = NSMenuItem(title: "Keep awake indefinitely", action: #selector(keepInfinite), keyEquivalent: "")
        infiniteItem.target = self
        infiniteItem.tag = MenuTag.keepInfinite.rawValue
        mainMenu.addItem(infiniteItem)

        let stopItem = NSMenuItem(title: "Off (keep using the selected power plan)", action: #selector(stopAwake), keyEquivalent: "")
        stopItem.target = self
        stopItem.tag = MenuTag.stop.rawValue
        mainMenu.addItem(stopItem)

        mainMenu.addItem(NSMenuItem.separator())

        let displayItem = NSMenuItem(title: "Keep screen on", action: #selector(toggleDisplay), keyEquivalent: "")
        displayItem.target = self
        displayItem.tag = MenuTag.displayToggle.rawValue
        mainMenu.addItem(displayItem)

        mainMenu.addItem(NSMenuItem.separator())

        let exitItem = NSMenuItem(title: "Exit", action: #selector(exitApp), keyEquivalent: "q")
        exitItem.target = self
        exitItem.tag = MenuTag.exit.rawValue
        mainMenu.addItem(exitItem)

        statusItem.menu = mainMenu
    }

    func updateIcon() {
        let icon: NSImage?
        switch awakeMode {
        case .none:
            icon = iconDisabled
        case .min30, .hour1, .hour2:
            icon = iconTimed
        case .infinite:
            icon = iconIndefinite
        }

        let modeText: String
        switch awakeMode {
        case .none:
            modeText = "Off"
        case .min30:
            modeText = "30 min"
        case .hour1:
            modeText = "1 hour"
        case .hour2:
            modeText = "2 hours"
        case .infinite:
            modeText = "Indefinite"
        }

        statusItem.button?.image = icon
        statusItem.button?.toolTip = "Mini Awake - \(modeText)"
    }

    func releaseAllAssertions() {
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }
    }

    func applyAssertions() {
        releaseAllAssertions()

        if awakeMode == .none { return }

        let reason = "MiniAwake keeping system awake" as CFString

        if keepDisplayOn {
            IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &displayAssertionID
            )
        }

        IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &systemAssertionID
        )
    }

    func startWatchdog() {
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.awakeMode != .none {
                self.applyAssertions()
            }
        }
    }

    func updateMenuItems() {
        if let displayItem = mainMenu.item(withTag: MenuTag.displayToggle.rawValue) {
            displayItem.isEnabled = (awakeMode != .none)
            displayItem.state = keepDisplayOn ? .on : .off
        }
    }

    func keepAwake(minutes: Int, mode: AwakeMode) {
        awakeMode = mode
        keepDisplayOn = false
        applyAssertions()
        updateIcon()
        updateMenuItems()

        tickTimer?.invalidate()

        if minutes > 0 {
            endTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
            tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self, let end = self.endTime else { return }
                if self.awakeMode == .infinite { return }
                if Date() >= end {
                    self.stopAwake()
                }
            }
        }
    }

    @objc func keep30m()  { keepAwake(minutes: 30,  mode: .min30) }
    @objc func keep1h()   { keepAwake(minutes: 60,  mode: .hour1) }
    @objc func keep2h()   { keepAwake(minutes: 120, mode: .hour2) }
    @objc func keepInfinite() { keepAwake(minutes: 0, mode: .infinite) }

    @objc func stopAwake() {
        awakeMode = .none
        keepDisplayOn = false

        tickTimer?.invalidate()
        tickTimer = nil
        endTime = nil

        releaseAllAssertions()
        updateIcon()
        updateMenuItems()
    }

    @objc func toggleDisplay() {
        guard awakeMode != .none else { return }
        keepDisplayOn.toggle()
        applyAssertions()
        updateMenuItems()
    }

    @objc func exitApp() {
        stopAwake()
        watchdogTimer?.invalidate()
        NSApp.terminate(nil)
    }

    func menuWillOpen(_ menu: NSMenu) {
        if menu === intervalSubMenu {
            for item in intervalSubMenu.items {
                item.state = .off
            }
            switch awakeMode {
            case .min30:
                intervalSubMenu.item(withTag: MenuTag.keep30m.rawValue)?.state = .on
            case .hour1:
                intervalSubMenu.item(withTag: MenuTag.keep1h.rawValue)?.state = .on
            case .hour2:
                intervalSubMenu.item(withTag: MenuTag.keep2h.rawValue)?.state = .on
            default:
                break
            }
        } else if menu === mainMenu {
            if let intervalParent = mainMenu.item(at: 0) {
                switch awakeMode {
                case .min30, .hour1, .hour2:
                    intervalParent.state = .on
                default:
                    intervalParent.state = .off
                }
            }

            mainMenu.item(withTag: MenuTag.keepInfinite.rawValue)?.state =
                (awakeMode == .infinite) ? .on : .off

            mainMenu.item(withTag: MenuTag.stop.rawValue)?.state =
                (awakeMode == .none) ? .on : .off

            if let displayItem = mainMenu.item(withTag: MenuTag.displayToggle.rawValue) {
                displayItem.state = keepDisplayOn ? .on : .off
                displayItem.isEnabled = (awakeMode != .none)
            }
        }
    }
}

extension NSImage {
    func menuBarIcon(size: NSSize) -> NSImage {
        let img = NSImage(size: size)
        img.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: size),
                  from: .zero, operation: .sourceOver, fraction: 1.0)
        img.unlockFocus()
        img.isTemplate = false
        return img
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
