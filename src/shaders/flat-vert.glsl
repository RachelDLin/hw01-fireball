#version 300 es
precision highp float;

// The vertex shader used to render the background of the scene

uniform vec4 u_Color;

in vec4 vs_Pos;
out vec2 fs_Pos;

void main() {
  fs_Pos = vs_Pos.xy;
  gl_Position = vs_Pos;
}
