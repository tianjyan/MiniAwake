# MiniAwake

A lightweight system tray utility that prevents your computer from going to sleep, inspired by Microsoft PowerToys' Awake functionality.

## Features

- Keep your system awake for a specific duration (30 minutes, 1 hour, 2 hours)
- Keep your system awake indefinitely
- Optionally keep the display on while preventing sleep
- Minimal memory footprint
- Simple system tray interface
- No installation required - just run the executable

## How It Works

MiniAwake uses the Windows `SetThreadExecutionState` API to prevent the system from entering sleep mode. It runs quietly in your system tray, allowing you to easily enable or disable the awake functionality with just a few clicks.

## Usage

1. Run MiniAwake.exe
2. Right-click the system tray icon to access the menu
3. Select your desired awake duration:
   - 30 minutes
   - 1 hour
   - 2 hours
   - Indefinitely
4. Optionally enable "Keep screen on" to prevent the display from turning off
5. Select "Off" to return to normal power management

## System Tray Icons

- **Disabled**: MiniAwake is not preventing sleep
- **Timed**: MiniAwake is keeping the system awake for a specific duration
- **Indefinite**: MiniAwake is keeping the system awake indefinitely

## Advantages Over PowerToys Awake

- **Standalone Application**: No need to install the entire PowerToys suite
- **Lightweight**: Minimal memory usage and system resources
- **Simple Interface**: Easy-to-use system tray menu
- **Portable**: No installation required, can be run from any location

## Requirements

- Windows 7 or later
- Approximately 2MB of disk space
- Minimal RAM usage (typically less than 5MB when running)

## Building

MiniAwake is built using C++ and can be compiled with Visual Studio. The project includes:

- Main application code (`main.cpp`)
- Resource files for icons and UI elements
- Visual Studio project files

To build:

1. Open `MiniAwake.sln` in Visual Studio
2. Select your desired build configuration (Release/Debug)
3. Build the solution

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.