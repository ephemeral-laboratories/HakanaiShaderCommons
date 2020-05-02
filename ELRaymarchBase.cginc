#ifndef EL_RAYMARCH_BASE_CGINC
#define EL_RAYMARCH_BASE_CGINC

struct ELRaymarchBaseVertexInput
{
    float4 vertex   : POSITION;
    float3 normal   : NORMAL;
    float4 tangent  : TANGENT;
    float4 color    : COLOR;
};

struct ELRaymarchBaseVertexOutput
{
    float4 pos              : SV_POSITION;
    float4 grabPos          : TEXCOORD0;
    float4 objectPos        : TEXCOORD1;
    float3 objectNormal     : NORMAL;
    float3 objectRayStart   : TEXCOORD2;
    float3 objectRayDir     : TEXCOORD3;
};

struct ELRay
{
    float3 start;
    float3 dir;
    float t;
    float3 pos;
};

ELRaymarchBaseVertexOutput ELRaymarchBaseVertex(ELRaymarchBaseVertexInput input)
{
    ELRaymarchBaseVertexOutput output;
    UNITY_INITIALIZE_OUTPUT(ELRaymarchBaseVertexOutput, output);
    output.pos = UnityObjectToClipPos(input.vertex);
    output.grabPos = ComputeGrabScreenPos(output.pos);
    output.objectPos = input.vertex;
    output.objectNormal = input.normal;
    if (UNITY_MATRIX_P[3][3] == 1.0)
    {
        output.objectRayDir = ELWorldToObjectNormal(-UNITY_MATRIX_V[2].xyz);
        output.objectRayStart = input.vertex - normalize(output.objectRayDir);
    }
    else
    {
        output.objectRayStart = ELWorldToObjectPos(UNITY_MATRIX_I_V._m03_m13_m23);
        output.objectRayDir = input.vertex - output.objectRayStart;
    }
    return output;
}

ELRay ELGetRay(ELRaymarchBaseVertexOutput input)
{
    ELRay ray;
    ray.start = input.objectRayStart;
    ray.dir = normalize(input.objectRayDir);
	ray.t = 0.0;
    ray.pos = ray.start;
    return ray;
}

void ELAdvanceRay(inout ELRay ray, float dt)
{
    ray.t += dt;
    ray.pos = ray.start + ray.dir * ray.t;
}

#endif