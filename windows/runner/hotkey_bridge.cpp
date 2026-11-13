#include "hotkey_bridge.h"

#include <flutter/standard_method_codec.h>

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

// Our ids live in 0x5000.. so they never meet another part of the app.
constexpr int kIdBase = 0x5000;

int GetInt(const EncodableMap& m, const char* key, int fallback = 0) {
  auto it = m.find(EncodableValue(key));
  if (it == m.end()) return fallback;
  if (const auto* i = std::get_if<int32_t>(&it->second)) return *i;
  if (const auto* l = std::get_if<int64_t>(&it->second)) return static_cast<int>(*l);
  return fallback;
}

bool GetBool(const EncodableMap& m, const char* key) {
  auto it = m.find(EncodableValue(key));
  if (it == m.end()) return false;
  const auto* b = std::get_if<bool>(&it->second);
  return b && *b;
}

}  // namespace

HotkeyBridge::HotkeyBridge(HWND hwnd, flutter::BinaryMessenger* messenger) : hwnd_(hwnd) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "prism/hotkeys", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() != "set") {
      result->NotImplemented();
      return;
    }
    Clear();
    EncodableList refused;
    if (const auto* list = std::get_if<EncodableList>(call.arguments())) {
      for (const auto& item : *list) {
        const auto* m = std::get_if<EncodableMap>(&item);
        if (!m) continue;
        const int id = GetInt(*m, "id", -1);
        const int vk = GetInt(*m, "vk");
        if (id < 0 || id > 0xBFFF - kIdBase || vk <= 0) continue;
        UINT mods = static_cast<UINT>(GetInt(*m, "mods")) & (MOD_ALT | MOD_CONTROL | MOD_SHIFT | MOD_WIN);
        // Toggles fire once per press; volume keeps going while held.
        if (!GetBool(*m, "repeat")) mods |= MOD_NOREPEAT;
        if (::RegisterHotKey(hwnd_, kIdBase + id, mods, static_cast<UINT>(vk))) {
          registered_.push_back(kIdBase + id);
        } else {
          refused.push_back(EncodableValue(id));  // another app already has it
        }
      }
    }
    result->Success(EncodableValue(refused));
  });
}

HotkeyBridge::~HotkeyBridge() {
  Clear();
  if (channel_) channel_->SetMethodCallHandler(nullptr);
}

void HotkeyBridge::Clear() {
  for (int id : registered_) ::UnregisterHotKey(hwnd_, id);
  registered_.clear();
}

void HotkeyBridge::Pressed(WPARAM id) {
  const int ours = static_cast<int>(id) - kIdBase;
  if (ours < 0 || !channel_) return;
  channel_->InvokeMethod("pressed", std::make_unique<EncodableValue>(ours));
}
