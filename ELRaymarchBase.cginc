#ifndef EL_RAYMARCH_BASE_CGINC
#define EL_RAYMARCH_BASE_CGINC

#include "ELRaycastBase.cginc"

float2 ELMap(float3 objectPos);

float3 ELRaymarchNormal(in float3 objectPos)
{
    static const float2 e = fixed2(0.000001, -0.000001);
    return normalize(e.xyy * ELMap(objectPos + e.xyy).x +
                     e.yyx * ELMap(objectPos + e.yyx).x +
                     e.yxy * ELMap(objectPos + e.yxy).x +
                     e.xxx * ELMap(objectPos + e.xxx).x);
}

#define MAX_STEPS 200
// #define MAX_STEPS 80
#define MIN_DISTANCE 0.00001
#define MAX_DISTANCE 200.0

bool ELRaymarch(ELRay ray, out float3 objectPos, out float material)
{
    float2 mapResult;

    for (uint i = 0; i < MAX_STEPS; i++)
    {
        mapResult = ELMap(ray.pos);
        objectPos = ray.pos;

        if (mapResult.x > MAX_DISTANCE)
        {
            return false;
        }

        ELAdvanceRay(ray, mapResult.x);

        if (mapResult.x < MIN_DISTANCE)
        {
            material = mapResult.y;
            return true;
        }
    }

    material = mapResult.y;
    return true;
}

void ELDecodeMaterial(ELRaycastBaseFragmentInput input, float material, inout SurfaceOutputStandard output);

bool ELFragmentRaymarch(ELRaycastBaseFragmentInput input, out float3 objectPos, out float material)
{
    return ELRaymarch(ELGetRay(input), objectPos, material);
}

SurfaceOutputStandard ELRaymarchSurface(ELRaycastBaseFragmentInput input, out float3 objectPos, out float3 objectNormal)
{
    float material;
    bool hit = ELFragmentRaymarch(input, objectPos, material);

    // Save lighting calculations when not hit
    UNITY_BRANCH
    if (!hit)
    {
        clip(-1.0);
    }

    objectNormal = ELRaymarchNormal(objectPos);

    SurfaceOutputStandard output;
    UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, output);
    output.Normal = UnityObjectToWorldNormal(objectNormal);
    output.Occlusion = 1.0;
    ELDecodeMaterial(input, material, output);

    return output;
}

ELRaycastBaseFragmentOutput ELRaymarchFragment(ELRaycastBaseFragmentInput input)
{
    float3 objectPos;
    float3 objectNormal;
    SurfaceOutputStandard surfaceOutput = ELRaymarchSurface(input, objectPos, objectNormal);

    ELRaycastBaseFragmentOutput output;
    output.color = ELSurfaceFragment(surfaceOutput, objectPos, objectNormal);

    float4 clipPos = UnityObjectToClipPos(float4(objectPos, 1.0));
    output.clipDepth = clipPos.z / clipPos.w;

    return output;
}

float4 ELRaymarchShadowCasterFragment(ELRaycastBaseFragmentInput input) : SV_Target
{
    float3 objectPos;
    float materialUnused;
    bool hit = ELFragmentRaymarch(input, objectPos, materialUnused);
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

#endif