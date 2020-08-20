#ifndef EL_RAYMARCH_BASE_CGINC_
#define EL_RAYMARCH_BASE_CGINC_

#include "ELRaycastBase.cginc"
#include "ELRaymarchCommon.cginc"

// Implementing function defined in `ELRaycastBase.cginc`
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