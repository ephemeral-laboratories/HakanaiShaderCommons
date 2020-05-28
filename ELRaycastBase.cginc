#ifndef EL_RAYCAST_BASE_CGINC_
#define EL_RAYCAST_BASE_CGINC_

#include "ELRaycastBaseInputOutput.cginc"
#include "ELRaycastBaseRays.cginc"
#include "ELScuttledUnityLighting.cginc"

ELRaycastBaseFragmentInput ELRaycastBaseVertex(ELRaycastBaseVertexInput input)
{
    ELRaycastBaseFragmentInput output;
    UNITY_INITIALIZE_OUTPUT(ELRaycastBaseFragmentInput, output);
    output.pos = UnityObjectToClipPos(input.vertex);
    output.grabPos = ComputeGrabScreenPos(output.pos);
    output.objectPos = input.vertex;
    output.objectNormal = input.normal;
    output.color = input.color;
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


bool ELRaycast(ELRay ray, out float3 objectPos, out float3 objectNormal, out float material);


void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output);

bool ELFragmentRaycast(ELRaycastBaseFragmentInput input, out float3 objectPos, out float3 objectNormal, out float material)
{
    return ELRaycast(ELGetRay(input), objectPos, objectNormal, material);
}

SurfaceOutputStandard ELRaycastSurface(ELRaycastBaseFragmentInput input, out float3 objectPos, out float3 objectNormal)
{
    float material;
    bool hit = ELFragmentRaycast(input, objectPos, objectNormal, material);

    // Save lighting calculations when not hit
    UNITY_BRANCH
    if (!hit)
    {
        clip(-1.0);
        // TODO: Should be returning here!
    }

    SurfaceOutputStandard output;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, output);
    output.Normal = UnityObjectToWorldNormal(objectNormal);
    output.Occlusion = 1.0;
    ELDecodeMaterial(input, material, output);

    return output;
}

ELRaycastBaseFragmentOutput ELRaycastFragment(ELRaycastBaseFragmentInput input)
{
    float3 objectPos;
    float3 objectNormal;
    SurfaceOutputStandard surfaceOutput = ELRaycastSurface(input, objectPos, objectNormal);

    ELRaycastBaseFragmentOutput output;
    output.color = ELSurfaceFragment(surfaceOutput, objectPos, objectNormal);

    float4 clipPos = UnityObjectToClipPos(float4(objectPos, 1.0));
    output.clipDepth = clipPos.z / clipPos.w;

    return output;
}

float4 ELRaycastShadowCasterFragment(ELRaycastBaseFragmentInput input) : SV_Target
{
    float3 objectPos;
    float3 objectNormalUnused;
    float materialUnused;
    bool hit = ELFragmentRaycast(input, objectPos, objectNormalUnused, materialUnused);
    clip(hit ? 1.0 : -1.0);

    // Has to be called `v` because `TRANSFER_SHADOW_CASTER` sucks
    struct
    {
        float4 vertex;
    } v;
    v.vertex = float4(objectPos, 1.0);

    struct
    {
        V2F_SHADOW_CASTER;
    } output;
    TRANSFER_SHADOW_CASTER(output);

    SHADOW_CASTER_FRAGMENT(output);
}

#endif // EL_RAYCAST_BASE_CGINC_