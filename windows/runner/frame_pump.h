#ifndef RUNNER_FRAME_PUMP_H_
#define RUNNER_FRAME_PUMP_H_

#include <windows.h>

#include <atomic>
#include <thread>

// Wakes Flutter's task runner in step with the screen.
//
// Flutter on Windows starts each frame from a timer that only fires on the
// system tick (15.6 ms), so the app is stuck at 64 fps on every screen, out of
// step with its real refresh rate: on a 120 Hz display motion looks uneven.
// This thread waits for each display refresh (DwmFlush) and nudges the task
// runner, so a due frame starts right then. If the runner window can't be found
// (another engine version), nothing changes: the app is just back to 64 fps.
class FramePump {
 public:
  FramePump() = default;
  ~FramePump();

  void Start(HWND top_level);
  void Stop();

 private:
  void Run(HWND top_level);

  std::thread thread_;
  std::atomic<bool> stop_{false};
};

#endif  // RUNNER_FRAME_PUMP_H_
