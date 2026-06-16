#ifndef NATIVE_INPUT_DIALOG_H_
#define NATIVE_INPUT_DIALOG_H_

#include <windows.h>
#include <string>
#include <optional>

// Shows a native Windows input dialog with proper Korean IME support.
// Returns the entered text, or std::nullopt if cancelled.
std::optional<std::wstring> ShowNativeInputDialog(HWND parent);

#endif  // NATIVE_INPUT_DIALOG_H_
