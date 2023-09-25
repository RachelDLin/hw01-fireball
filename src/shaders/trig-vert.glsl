#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform int u_Time;

uniform float u_noiseAmp;
uniform int u_noisePeriod;
uniform float u_flameHeight;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out float dist_Val;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

float noise3D(vec3 v) {
    return fract(sin(dot(v, vec3(78, 13, 37))) * 43758.5453);
}

float mySmoothStep(float a, float b, float t) {
    //t = smoothstep(0, 1, t);
    //return mix(a, b, t);
    return 1.f;
}

float interpNoise3D(vec3 p) {
    float intX = (floor(p.x));
    float fractX = fract(p.x);
    float intY = (floor(p.y));
    float fractY = fract(p.y);
    float intZ = (floor(p.z));
    float fractZ = fract(p.z);
    
    float a = noise3D(vec3(intX, intY, intZ));
    float b = noise3D(vec3(intX + 1.f, intY, intZ));
    float c = noise3D(vec3(intX, intY + 1.f, intZ));
    float d = noise3D(vec3(intX, intY, intZ + 1.f));
    float e = noise3D(vec3(intX + 1.f, intY + 1.f, intZ));
    float f = noise3D(vec3(intX + 1.f, intY, intZ + 1.f));
    float g = noise3D(vec3(intX, intY, intZ + 1.f));
    float h = noise3D(vec3(intX + 1.f, intY + 1.f, intZ + 1.f));    
   
    float i1 = mix(a, b, fractX);
    float i2 = mix(c, d, fractX);
    float i3 = mix(e, f, fractX);
    float i4 = mix(g, h, fractX);
    float j1 = mix(i1, i2, fractY);
    float j2 = mix(i3, i4, fractY);
    return mix(j1, j2, fractZ);
}

float fbm(vec3 v) {
    float total = 0.f;
    float persistence = 0.5;
    int octaves = 8;
    float freq = 2.f;
    float amp = 0.5;
    for (int i = 1; i <= octaves; i++) {
        total += amp * interpNoise3D(v.xyz * freq);
        freq *= 2.f;
        amp *= persistence;
    }

    return total;
}

float triangle_wave(float x, float freq, float amplitude) {
    return abs(mod((x * freq), amplitude) - (0.5 * amplitude));
}

void main()
{
    
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    float amp = u_noiseAmp;
    float period = float(u_noisePeriod);
    float t = 0.5f * sin(float(u_Time) * 0.01) + 1.f;

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    float dir = dot(normalize(vs_Pos.xyz), normalize(fs_LightVec.xyz)); // 1 = parallel, 0 = perp

    fs_Pos = vs_Pos;

    float height = u_flameHeight;
    if (dir > 0.f) {
        fs_Pos = mix(fs_Pos, vec4(height), dir);
    }
    

    float p1a = amp * sin(vs_Pos.x * float(u_Time) / 7.f + 0.014);
    float p1b = amp * cos(vs_Pos.y * float(u_Time) / 5.f + 0.02);
    float p1c = amp * sin(vs_Pos.z * float(u_Time) / 6.f + 0.013);
    float p1 = (p1a + p1b + p1c) / 3.f;

    float p2a = amp * sin(vs_Pos.x * float(u_Time) / 6.f + 0.018);
    float p2b = amp * cos(vs_Pos.y * float(u_Time) / 9.f + 0.01);
    float p2c = amp * sin(vs_Pos.z * float(u_Time) / 8.f + 0.016);
    float p2 = (p2a + p2b + p2c) / 3.f;
    
    float d1 = 0.3 * fbm(vs_Pos.xyz * sin(float(u_Time) / period + vec3(0.4, 0.3, 0.1)));
    float d2 = 0.2 * fbm(vs_Pos.xyz * sin(float(u_Time) / period + vec3(0.2, 0.5, 0.7)));
    float R = 1.f;
    vec3 startPos = normalize(modelposition.xyz) * ((2.f * p1 * d1));
    vec3 endPos = normalize(modelposition.xyz) * ((2.f * p2 * d2));

    vec3 fPos = (vec3(startPos) * (1.f - (t / 2.f))) + (vec3(endPos) * t) / 2.f;
    
    fs_Pos += vec4(fPos, vs_Pos.w);

    float d3 = abs(length(fs_Pos));
    float d4 = height + (2.f * (0.4 + (0.4 * amp))) + (2.f * (0.3 + (0.3 * amp)));
    dist_Val = (d3 / d4);
    
    
    

    gl_Position = u_ViewProj * fs_Pos;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
