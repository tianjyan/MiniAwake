# MiniAwake

A lightweight system tray / menu bar utility that prevents your computer from going to sleep, inspired by Microsoft PowerToys' Awake functionality. Available for both Windows and macOS.

## Features

- Keep your system awake for a specific duration (30 minutes, 1 hour, 2 hours)
- Keep your system awake indefinitely
- Optionally keep the display on while preventing sleep
- Minimal memory footprint (< 5MB)
- Simple tray/menu bar interface
- Portable — no installation required

## Usage

### Windows

1. Run `MiniAwake.exe`
2. Right-click the system tray icon to access the menu
3. Select your desired awake duration
4. Optionally enable "Keep screen on"
5. Select "Off" to return to normal power management

### macOS

1. Open `MiniAwake.app`
2. Click the menu bar icon to access the menu
3. Select your desired awake duration
4. Optionally enable "Keep screen on"
5. Select "Off" to return to normal power management

## Icons

| Icon | State |
|------|-------|
| Disabled | MiniAwake is not preventing sleep |
| Timed | Keeping awake for a specific duration |
| Indefinite | Keeping awake indefinitely |

## How It Works

| Platform | API |
|----------|-----|
| Windows | [`SetThreadExecutionState`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate) with `ES_SYSTEM_REQUIRED` / `ES_DISPLAY_REQUIRED` |
| macOS | [`IOPMAssertionCreateWithName`](https://developer.apple.com/documentation/iokit/1557134-iopmassertioncreatewithname) with `kIOPMAssertionTypePreventUserIdleSystemSleep` / `kIOPMAssertionTypePreventUserIdleDisplaySleep` |

## Requirements

### Windows
- Windows 7 or later
- ~2MB disk space

### macOS
- macOS 11 (Big Sur) or later
- ~2MB disk space

## Building

### Windows

Open `MiniAwake.sln` in Visual Studio and build.

### macOS

```bash
cd mac
make          # Release build
make debug    # Debug build
make run      # Build and launch
```

The macOS build requires Xcode Command Line Tools (`xcode-select --install`).

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
