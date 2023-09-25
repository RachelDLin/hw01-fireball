#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform int u_Time;
uniform vec4 u_Color;

in vec2 fs_Pos;
out vec4 out_Col;

float noise2D(vec2 v) {
    return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

float interpNoise2D(vec2 p) {
    float intX = (floor(p.x));
    float fractX = fract(p.x);
    float intY = (floor(p.y));
    float fractY = fract(p.y);
    
    float a = noise2D(vec2(intX, intY));
    float b = noise2D(vec2(intX + 1.f, intY));
    float c = noise2D(vec2(intX, intY + 1.f));
    float d = noise2D(vec2(intX + 1.f, intY + 1.f));
    
    float i1 = mix(a, b, fractX);
    float i2 = mix(c, d, fractX);
    return mix(i1, i2, fractY);
}

float fbm(vec2 v) {
    float total = 0.f;
    float persistence = 0.5;
    int octaves = 8;
    float freq = 2.f;
    float amp = 0.5;

    mat2 rot = mat2(cos(0.5), sin(0.5), 
                    -sin(0.5), cos(0.5));

    for (int i = 0; i < octaves; i++) {
        total += amp * interpNoise2D(v.xy);
        v = rot * v * freq + vec2(100.0);
        amp *= persistence;
    }

    return total;
}

void main() {
  //out_Col = vec4(0.5 * (fs_Pos + vec2(1.0)), 0.5 * (sin(u_Time * 3.14159 * 0.01) + 1.0), 1.0);
  
  /*
  float n = abs(sin(float(u_Time) * 0.1) * 3.f);
  //fs_Pos += fs_Pos * vec2(n);
  vec2 q = vec2(0.f);
  q.x = fbm(fs_Pos + vec2(0.f));
  q.y = fbm(fs_Pos + vec2(float(u_Time)));

  vec2 r = vec2(0.f);
  r.x = fbm(fs_Pos + 1.f * q + vec2(1.7, 9.2) + 0.15 * float(u_Time));
  r.y = fbm(fs_Pos + 1.f * q + vec2(8.3, 2.8) + 0.126 * float(u_Time));
  
  float f = fbm(fs_Pos + r);

  vec3 color = vec3(0.f);

  color = mix(vec3(0.101961,0.619608,0.666667), 
                vec3(0.666667, 0.666667, 0.498039),
                clamp((f * f) * 4.f, 0.f, 1.f));
  
  color = mix(color,
              vec3(0.f, 0.f, 0.164706),
              clamp(length(q), 0.0, 1.0));

  color = mix(color,
              vec3(0.666667, 1.f, 1.f),
              clamp(length(r), 0.0, 1.0));

  out_Col = vec4((f * f * f + 0.6 * f * f + 0.5 * f) * color, 1.f);
  */
  float t = fbm(fs_Pos + vec2(fbm(fs_Pos + vec2(fbm(fs_Pos)))));

  float tint = 3.f;
  float brightness = 1.6f;
  out_Col = mix(vec4(0.0, 0.0, 0.0, 1.0), u_Color / tint, (1.f - t) * brightness);
}
