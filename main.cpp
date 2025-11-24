#include <windows.h>
#include <shellapi.h>
#include <thread>
#include <atomic>
#include <chrono>
#include "Resource.h"  // Icon resource IDs

#define ID_TRAY_APP_ICON  1001
#define ID_TRAY_KEEP_30M  1002
#define ID_TRAY_KEEP_1H   1003
#define ID_TRAY_KEEP_2H   1004
#define ID_TRAY_KEEP_INF  1005
#define ID_TRAY_STOP      1006
#define ID_TRAY_DISPLAY   1007
#define ID_TRAY_EXIT      1008

NOTIFYICONDATA nid;
HMENU hMenu;

std::atomic<bool> keepAwakeRunning(false);
std::thread timerThread;
enum AwakeMode { NONE, MIN30, HOUR1, HOUR2, INFINITE_MODE };
AwakeMode currentMode = NONE;
bool keepDisplayOn = false;

// Icon handles
HICON hIconDisabled;
HICON hIconIndefinite;
HICON hIconTimed;

// ---------------------
// Unified function to apply current execution state
// 
// run "powercfg /requests" in cmd to check states
// ---------------------
void ApplyExecutionState() {
    DWORD flags = ES_CONTINUOUS;
    if (keepAwakeRunning)
        flags |= ES_SYSTEM_REQUIRED;
    if (keepDisplayOn)
        flags |= ES_DISPLAY_REQUIRED;

    SetThreadExecutionState(flags);
}

// ---------------------
// Update tray icon according to current state
// ---------------------
void UpdateTrayIcon() {
    if (currentMode == NONE) {
        nid.hIcon = hIconDisabled;
    }
    else if (currentMode == INFINITE_MODE) {
        nid.hIcon = hIconIndefinite;
    }
    else {
        nid.hIcon = hIconTimed;
    }
    Shell_NotifyIcon(NIM_MODIFY, &nid);
}

// ---------------------
// Start keeping system awake
// ---------------------
void KeepAwake(int minutes, AwakeMode mode, HWND hWnd){
    // Notify previous thread to stop
    keepAwakeRunning = false;
    currentMode = NONE;

    if (timerThread.joinable()) {
        timerThread.join();
    }

    keepAwakeRunning = true;
    currentMode = mode;
    ApplyExecutionState();
    UpdateTrayIcon();

    if (minutes > 0) {
        timerThread = std::thread([minutes, hWnd]() {
            using namespace std::chrono;
            auto start = steady_clock::now();
            auto duration = duration_cast<seconds>(std::chrono::minutes(minutes));
            auto end = start + duration;

            while (keepAwakeRunning && steady_clock::now() < end) {
                Sleep(500);
            }

            if (currentMode == INFINITE_MODE)
                return

            PostMessage(hWnd, WM_USER + 2, 0, 0);
        });
    }
}
// ---------------------
// Stop keeping system awake
// ---------------------
void StopKeepAwake() {
    keepAwakeRunning = false;
    currentMode = NONE;
    keepDisplayOn = false;
    ApplyExecutionState();
    UpdateTrayIcon();

    if (timerThread.joinable()) timerThread.join();
}

// ---------------------
// Add tray icon
// ---------------------
void AddTrayIcon(HINSTANCE hInstance, HWND hWnd) {
    nid.cbSize = sizeof(NOTIFYICONDATA);
    nid.hWnd = hWnd;
    nid.uID = ID_TRAY_APP_ICON;
    nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    nid.uCallbackMessage = WM_USER + 1;
    nid.hIcon = hIconDisabled;
    lstrcpy(nid.szTip, TEXT("Mini Awake"));
    Shell_NotifyIcon(NIM_ADD, &nid);
}

// ---------------------
// Show tray menu
// ---------------------
void ShowTrayMenu(HWND hWnd) {
    POINT pt;
    GetCursorPos(&pt);
    hMenu = CreatePopupMenu();
    HMENU hSub = CreatePopupMenu();

    // Keep awake intervals
    AppendMenu(hSub, MF_STRING | (currentMode == MIN30 ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_KEEP_30M, TEXT("30 minutes"));
    AppendMenu(hSub, MF_STRING | (currentMode == HOUR1 ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_KEEP_1H, TEXT("1 hour"));
    AppendMenu(hSub, MF_STRING | (currentMode == HOUR2 ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_KEEP_2H, TEXT("2 hours"));
    AppendMenu(hMenu, MF_POPUP | (currentMode == MIN30 || currentMode == HOUR1 || currentMode == HOUR2 ? MF_CHECKED : MF_UNCHECKED), (UINT_PTR)hSub, TEXT("Keep awake on interval"));

    // Infinite mode
    AppendMenu(hMenu, MF_STRING | (currentMode == INFINITE_MODE ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_KEEP_INF, TEXT("Keep awake indefinitely"));

    // Stop
    AppendMenu(hMenu, MF_STRING | (currentMode == NONE ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_STOP, TEXT("Off (keep using the selected power plan)"));
    AppendMenu(hMenu, MF_SEPARATOR , 0, NULL);

    // Keep display on
    UINT displayFlags = MF_STRING;
    displayFlags |= (keepDisplayOn ? MF_CHECKED : MF_UNCHECKED);
    displayFlags |= (currentMode == NONE ? MF_GRAYED : MF_ENABLED); // Disable in NONE mode
    AppendMenu(hMenu, displayFlags, ID_TRAY_DISPLAY, TEXT("Keep screen on"));

    AppendMenu(hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenu(hMenu, MF_STRING, ID_TRAY_EXIT, TEXT("Exit"));

    SetForegroundWindow(hWnd);
    TrackPopupMenu(hMenu, TPM_BOTTOMALIGN | TPM_LEFTALIGN, pt.x, pt.y, 0, hWnd, NULL);
    DestroyMenu(hSub);
    DestroyMenu(hMenu);
}

// ---------------------
// Window procedure
// ---------------------
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_USER + 1:
        if (lParam == WM_RBUTTONUP) {
            ShowTrayMenu(hWnd);
        }
        break;
    case WM_USER + 2:
        StopKeepAwake();
        break;
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case ID_TRAY_KEEP_30M: KeepAwake(30, MIN30, hWnd); break;
        case ID_TRAY_KEEP_1H:  KeepAwake(60, HOUR1, hWnd); break;
        case ID_TRAY_KEEP_2H:  KeepAwake(120, HOUR2, hWnd); break;
        case ID_TRAY_KEEP_INF: KeepAwake(0, INFINITE_MODE, hWnd); break;
        case ID_TRAY_STOP:     StopKeepAwake(); break;
        case ID_TRAY_DISPLAY:
            if (currentMode != NONE) {
                keepDisplayOn = !keepDisplayOn;
                ApplyExecutionState();
                UpdateTrayIcon();
            }
            break;
        case ID_TRAY_EXIT:
            StopKeepAwake();
            Shell_NotifyIcon(NIM_DELETE, &nid);
            PostQuitMessage(0);
            break;
        }
        break;
    case WM_DESTROY:
        StopKeepAwake();
        Shell_NotifyIcon(NIM_DELETE, &nid);
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// ---------------------
// Entry point
// ---------------------
int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int) {
    WNDCLASS wc = { 0 };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = TEXT("MiniAwakeClass");
    RegisterClass(&wc);

    // Load icon resources
    hIconDisabled = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_DISABLED));
    hIconIndefinite = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_INDEFINITE));
    hIconTimed = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_TIMED));

    HWND hWnd = CreateWindow(TEXT("MiniAwakeClass"), TEXT("MiniAwake"), 0, 0, 0, 0, 0, NULL, NULL, hInstance, NULL);
    AddTrayIcon(hInstance, hWnd);

    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    if (timerThread.joinable()) timerThread.join();
    return (int)msg.wParam;
}
