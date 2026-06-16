// native_input_dialog.cpp - Native Win32 input dialog for Korean IME support.
#include "native_input_dialog.h"
#include <commctrl.h>

#pragma comment(lib, "comctl32.lib")

static HWND g_edit_control = nullptr;
static std::wstring g_result;
static bool g_confirmed = false;

static INT_PTR CALLBACK DialogProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam) {
  switch (msg) {
    case WM_INITDIALOG: {
      // Center dialog on parent
      RECT rc;
      GetWindowRect(GetParent(hDlg), &rc);
      int cx = (rc.left + rc.right) / 2;
      int cy = (rc.top + rc.bottom) / 2;
      SetWindowPos(hDlg, nullptr, cx - 200, cy - 60, 0, 0, SWP_NOSIZE | SWP_NOZORDER);

      g_edit_control = GetDlgItem(hDlg, 101);
      SetFocus(g_edit_control);
      return FALSE;
    }
    case WM_COMMAND:
      if (LOWORD(wParam) == IDOK) {
        wchar_t buffer[1024] = {};
        GetDlgItemTextW(hDlg, 101, buffer, 1024);
        g_result = buffer;
        g_confirmed = true;
        EndDialog(hDlg, IDOK);
        return TRUE;
      } else if (LOWORD(wParam) == IDCANCEL) {
        g_confirmed = false;
        EndDialog(hDlg, IDCANCEL);
        return TRUE;
      }
      break;
    case WM_CLOSE:
      g_confirmed = false;
      EndDialog(hDlg, IDCANCEL);
      return TRUE;
  }
  return FALSE;
}

std::optional<std::wstring> ShowNativeInputDialog(HWND parent) {
  // Build dialog template in memory.
  // Creates a simple dialog with: static label, edit control, OK, Cancel.

  alignas(4) BYTE dlgTemplate[2048] = {};
  BYTE* p = dlgTemplate;

  // DLGTEMPLATE
  auto* dlg = reinterpret_cast<DLGTEMPLATE*>(p);
  dlg->style = DS_MODALFRAME | DS_CENTER | WS_POPUP | WS_CAPTION | WS_SYSMENU | DS_SETFONT;
  dlg->cdit = 4;
  dlg->cx = 280;
  dlg->cy = 90;
  p += sizeof(DLGTEMPLATE);

  // Menu (none)
  *reinterpret_cast<WORD*>(p) = 0; p += sizeof(WORD);
  // Class (default)
  *reinterpret_cast<WORD*>(p) = 0; p += sizeof(WORD);
  // Title (hex-escaped Korean)
  const wchar_t title[] = L"\xC0DD\xAC01 \xC801\xAE30";
  size_t titleLen = (wcslen(title) + 1) * sizeof(wchar_t);
  memcpy(p, title, titleLen); p += titleLen;
  // Font size
  *reinterpret_cast<WORD*>(p) = 9; p += sizeof(WORD);
  // Font name
  const wchar_t font[] = L"Segoe UI";
  size_t fontLen = (wcslen(font) + 1) * sizeof(wchar_t);
  memcpy(p, font, fontLen); p += fontLen;

  // Align to DWORD
  p = reinterpret_cast<BYTE*>((reinterpret_cast<uintptr_t>(p) + 3) & ~3);

  // --- Control 1: Static label ---
  auto* ctrl1 = reinterpret_cast<DLGITEMTEMPLATE*>(p);
  ctrl1->style = WS_CHILD | WS_VISIBLE | SS_LEFT;
  ctrl1->x = 10; ctrl1->y = 8; ctrl1->cx = 260; ctrl1->cy = 12;
  ctrl1->id = 100;
  p += sizeof(DLGITEMTEMPLATE);
  *reinterpret_cast<WORD*>(p) = 0xFFFF; p += sizeof(WORD);
  *reinterpret_cast<WORD*>(p) = 0x0082; p += sizeof(WORD);
  // Label text (hex-escaped Korean)
  const wchar_t label[] = L"\xB5A0\xC624\xB978 \xC0DD\xAC01\xC744 \xD558\xB098 \xC801\xC5B4\xC8FC\xC138\xC694.";
  size_t labelLen = (wcslen(label) + 1) * sizeof(wchar_t);
  memcpy(p, label, labelLen); p += labelLen;
  *reinterpret_cast<WORD*>(p) = 0; p += sizeof(WORD);
  p = reinterpret_cast<BYTE*>((reinterpret_cast<uintptr_t>(p) + 3) & ~3);

  // --- Control 2: Edit control ---
  auto* ctrl2 = reinterpret_cast<DLGITEMTEMPLATE*>(p);
  ctrl2->style = WS_CHILD | WS_VISIBLE | WS_BORDER | WS_TABSTOP | ES_AUTOHSCROLL;
  ctrl2->x = 10; ctrl2->y = 24; ctrl2->cx = 260; ctrl2->cy = 16;
  ctrl2->id = 101;
  p += sizeof(DLGITEMTEMPLATE);
  *reinterpret_cast<WORD*>(p) = 0xFFFF; p += sizeof(WORD);
  *reinterpret_cast<WORD*>(p) = 0x0081; p += sizeof(WORD);
  *reinterpret_cast<WORD*>(p) = 0; p += sizeof(WORD);
  *reinterpret_cast<WORD*>(p) = 0; p += sizeof(WORD);
  p = reinterpret_cast<BYTE*>((reinterpret_cast<uintptr_t>(p) + 3) & ~3);

  // --- Control 3: OK button ---
  auto* ctrl3 = reinterpret_cast<DLGITEMTEMPLATE*>(p);
  ctrl3->style = WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_DEFPUSHBUTTON;
  ctrl3->x = 120; ctrl3->y = 52; ctrl3->cx = 60; ctrl3->cy = 16;
  ctrl3->id = IDOK;
  p += sizeof(DLGITEMTEMPLATE);
  *reinterpret_cast<WORD*>(p) = 0xFFFF; p += sizeof(WORD);
  *reinterpret_cast<WORD*>(p) = 0x0080; p += sizeof(WORD);
  const wchar_t okText[] = L"\xCD94\xAC00";
  size_t okLen = (wcslen(okText) + 1) * sizeof(wchar_t);
  memcpy(p, okText, okLen); p += okLen;
  *reinterpret_cast<WORD*>(p) = 0; p += sizeof(WORD);
  p = reinterpret_cast<BYTE*>((reinterpret_cast<uintptr_t>(p) + 3) & ~3);

  // --- Control 4: Cancel button ---
  auto* ctrl4 = reinterpret_cast<DLGITEMTEMPLATE*>(p);
  ctrl4->style = WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON;
  ctrl4->x = 190; ctrl4->y = 52; ctrl4->cx = 60; ctrl4->cy = 16;
  ctrl4->id = IDCANCEL;
  p += sizeof(DLGITEMTEMPLATE);
  *reinterpret_cast<WORD*>(p) = 0xFFFF; p += sizeof(WORD);
  *reinterpret_cast<WORD*>(p) = 0x0080; p += sizeof(WORD);
  const wchar_t cancelText[] = L"\xCDE8\xC18C";
  size_t cancelLen = (wcslen(cancelText) + 1) * sizeof(wchar_t);
  memcpy(p, cancelText, cancelLen); p += cancelLen;
  *reinterpret_cast<WORD*>(p) = 0; p += sizeof(WORD);

  g_result.clear();
  g_confirmed = false;

  DialogBoxIndirectW(
    GetModuleHandle(nullptr),
    reinterpret_cast<DLGTEMPLATE*>(dlgTemplate),
    parent,
    DialogProc
  );

  if (g_confirmed && !g_result.empty()) {
    return g_result;
  }
  return std::nullopt;
}
