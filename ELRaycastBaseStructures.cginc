#ifndef EL_RAYCAST_BASE_STRUCTURES_CGINC
#define EL_RAYCAST_BASE_STRUCTURES_CGINC

struct ELRaycastBaseVertexInput
{
    float4 vertex   : POSITION;
    float4 color    : COLOR;
    float3 normal   : NORMAL;
    float4 tangent  : TANGENT;
    float2 texcoord : TEXCOORD0;
};

struct ELRaycastBaseFragmentInput
{
    float4 pos              : SV_POSITION;
    float4 color            : COLOR;
    float4 grabPos          : TEXCOORD0;
    float4 objectPos        : TEXCOORD1;
    float3 objectNormal     : NORMAL;
    float3 objectRayStart   : TEXCOORD2;
    float3 objectRayDir     : TEXCOORD3;
};

struct ELRaycastBaseFragmentOutput
{
    float4 color    : SV_Target;
    float clipDepth : SV_Depth;
};

#endif