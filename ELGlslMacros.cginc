#ifndef EL_GLSL_MACROS_CGINC_
#define EL_GLSL_MACROS_CGINC_

#define iTime _Time.y
#define iResolution _ScreenParams
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mix lerp
#define texture tex2D
#define fract frac
#define mat4 float4x4
#define mat3 float3x3
#define textureLod(a,b,c) tex2Dlod(a,float4(b,0,c))
#define atan(x,y) atan2(y,x)
#define mod(x,y) (x-y*floor(x/y)) // glsl mod

#endif // EL_GLSL_MACROS_CGINC_