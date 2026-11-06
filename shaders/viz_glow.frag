#version 460 core
#include <flutter/runtime_effect.glsl>

// A soft ball of light that breathes with the bass, with rings on the mids and
// fine shimmer on the highs. One draw call: all the work is on the GPU.

uniform vec2 uSize;
uniform float uTime;
uniform float uBass;
uniform float uMid;
uniform float uHigh;
uniform float uPulse;
uniform vec4 uInk;
uniform vec4 uLed;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - 0.5 * uSize) / min(uSize.x, uSize.y);
  float r = length(uv);
  float a = atan(uv.y, uv.x);

  float radius = 0.16 + 0.16 * uBass + 0.06 * uPulse;
  float wob = 0.012 * sin(a * 5.0 + uTime * 1.3) + 0.010 * sin(a * 9.0 - uTime * 2.1);
  float core = smoothstep(radius + 0.26 + wob, radius - 0.06, r);
  core = core * core;

  float rings = 0.0;
  for (int i = 0; i < 3; i++) {
    float t = fract(uTime * 0.18 + float(i) / 3.0);
    float rr = radius + t * 0.42;
    rings += (1.0 - t) * smoothstep(0.012 + uMid * 0.012, 0.0, abs(r - rr - wob));
  }
  rings *= 0.25 + 0.75 * uMid;

  float shimmer = hash(floor(FlutterFragCoord().xy / 3.0) + floor(uTime * 12.0));
  shimmer = step(0.985 - uHigh * 0.02, shimmer) * smoothstep(0.55, 0.1, r) * uHigh;

  vec3 color = uInk.rgb * (0.08 + 0.92 * core) * core + uInk.rgb * rings * 0.7 + uLed.rgb * uPulse * core * 0.35 + uInk.rgb * shimmer * 0.6;
  float alpha = clamp(core * 0.95 + rings * 0.7 + shimmer * 0.5, 0.0, 1.0);
  fragColor = vec4(color * alpha, alpha);
}
