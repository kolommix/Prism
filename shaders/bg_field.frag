#version 460 core
#include <flutter/runtime_effect.glsl>

// Procedural backgrounds on the GPU, one draw call per frame.
// uMode: 0 mesh gradient, 1 aurora, 2 liquid blobs.

uniform vec2 uSize;
uniform float uTime;
uniform float uMode;
uniform float uBass;
uniform vec2 uPointer;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform float uBright;
uniform float uDensity;
uniform float uScale;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p = p * 2.03 + vec2(13.1, 7.7);
    a *= 0.5;
  }
  return v;
}

vec3 mesh(vec2 uv) {
  vec3 c = uColorA * 0.18;
  float total = 0.0;
  vec3 sum = vec3(0.0);
  for (int i = 0; i < 5; i++) {
    float fi = float(i);
    vec2 p = vec2(0.5 + 0.45 * sin(uTime * (0.11 + fi * 0.023) + fi * 2.1),
                  0.5 + 0.45 * cos(uTime * (0.13 + fi * 0.017) + fi * 1.3));
    float d = distance(uv, p);
    float w = 1.0 / (0.02 + d * d * 6.0);
    vec3 tone = mix(uColorA, uColorB, 0.5 + 0.5 * sin(fi * 1.7 + uTime * 0.05));
    sum += tone * w;
    total += w;
  }
  return mix(c, sum / total, 0.85 + 0.15 * uBass);
}

vec3 aurora(vec2 uv) {
  vec3 col = uColorA * 0.04;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float x = uv.x * (1.4 + fi * 0.5) * uDensity;
    float wave = fbm(vec2(x + uTime * (0.05 + fi * 0.02), fi * 3.0 + uTime * 0.03));
    float y = 0.25 + fi * 0.14 + (wave - 0.5) * 0.5;
    float d = uv.y - y;
    float curtain = smoothstep(0.32, 0.0, abs(d)) * smoothstep(-0.32, 0.05, d);
    float streak = 0.55 + 0.45 * fbm(vec2(x * 8.0, uTime * 0.25 + fi));
    col += mix(uColorA, uColorB, fi / 2.0) * curtain * streak * (0.55 + 0.45 * uBass);
  }
  return col;
}

vec3 blobs(vec2 uv, float aspect) {
  vec2 q = vec2(uv.x * aspect, uv.y);
  float field = 0.0;
  float tone = 0.0;
  for (int i = 0; i < 7; i++) {
    float fi = float(i);
    vec2 p = vec2((0.5 + 0.46 * sin(uTime * (0.17 + fi * 0.031) + fi * 1.9)) * aspect,
                  0.5 + 0.46 * cos(uTime * (0.13 + fi * 0.027) + fi * 2.7));
    float r = (0.10 + 0.05 * sin(fi * 3.1 + uTime * 0.2)) * uScale * (1.0 + 0.3 * uBass);
    vec2 d = q - p;
    float f = r * r / (dot(d, d) + 1e-4);
    field += f;
    tone += f * (0.5 + 0.5 * sin(fi * 2.3));
  }
  float edge = smoothstep(0.85, 1.25, field);
  vec3 ink = mix(uColorA, uColorB, clamp(tone / max(field, 0.001), 0.0, 1.0));
  // Lit from above: the rim is a little brighter than the middle.
  float rim = smoothstep(1.2, 0.9, field) * edge;
  return ink * edge * (0.55 + 0.45 * rim) + uColorA * 0.03;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / uSize.y;
  vec3 c;
  if (uMode < 0.5) {
    c = mesh(uv);
  } else if (uMode < 1.5) {
    c = aurora(uv);
  } else {
    c = blobs(uv, aspect);
  }
  // A little light follows the mouse.
  if (uPointer.x >= 0.0) {
    float d = distance(vec2(uv.x * aspect, uv.y), vec2(uPointer.x * aspect, uPointer.y));
    c += uColorB * 0.05 * smoothstep(0.45, 0.0, d);
  }
  // A touch of noise stops gradients from banding.
  c += (hash(frag + fract(uTime)) - 0.5) / 128.0;
  fragColor = vec4(clamp(c * uBright, 0.0, 1.0), 1.0);
}
