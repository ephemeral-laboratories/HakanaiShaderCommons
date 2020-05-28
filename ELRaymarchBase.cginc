#ifndef EL_RAYMARCH_BASE_CGINC_
#define EL_RAYMARCH_BASE_CGINC_

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

bool ELRaycast(ELRay ray, out float3 objectPos, out float3 objectNormal, out float material)
{
    bool hit = ELRaymarch(ray, objectPos, material);

    // Avoid potential multiple map calls if it didn't hit at all
    UNITY_BRANCH
    if (hit)
    {
        objectNormal = ELRaymarchNormal(objectPos);
    }
    else
    {
        // Just to silence the warning
        objectNormal = float3(0.0, 0.0, 1.0);
    }

    return hit;
}

#endif // EL_RAYMARCH_BASE_CGINC_