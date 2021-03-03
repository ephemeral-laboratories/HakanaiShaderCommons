#ifndef EL_RAYMARCH_COMMON_CGINC_
#define EL_RAYMARCH_COMMON_CGINC_

#include "ELIntersectionFunctions.cginc"

/**
 * _Pseudo-abstract method, to be implemented by consumers._
 *
 * Called to get the signed distance from the raymarched object.
 *
 * @param objectPos the position, in object space.
 * @return a 2-element float vector:
 *         first element contains the signed distance from the object
 *         (negative when inside the object, positive when outside);
 *         second element contains a material value eventually passed
 *         to `ELDecodeMaterial`.
 */
float2 ELMap(float3 objectPos);

/**
 * _Pseudo-abstract method, to be implemented by consumers._
 *
 * Called to get a bounding box for the raycast.
 * The bounding box populated should encase the entire raymarch.
 *
 * @param boxMin the minimum X-Y-Z coordinates of the bounding box.
 * @param boxMax the maximum X-Y-Z coordinates of the bounding box.
 */
void ELBoundingBox(out float3 boxMin, out float3 boxMax);

/**
 * Calculates normal for a hit position on the raymarched object.
 *
 * @param objectPos the hit position, in object space.
 * @return the normal at that position, in object space.
 */
float3 ELRaymarchNormal(float3 objectPos)
{
    // Epsilon value for swizzling shortcuts.
    static const float3 e = float3(0.0001, -0.0001, 0.0);

    // Both the strategies below are essentially just:
    // - move a little in a direction
    // - figure how much further this took us from the surface
    // - multiply those two values together
    // - sum all those vectors and normalise to get normal

    #ifdef EL_CUBIC_NORMAL_STRATEGY
        // 6-sample version. Sometimes gives better results.
        return normalize(
            e.xzz * ELMap(objectPos + e.xzz).x +
            e.yzz * ELMap(objectPos + e.yzz).x +
            e.zxz * ELMap(objectPos + e.zxz).x +
            e.zyz * ELMap(objectPos + e.zyz).x +
            e.zzx * ELMap(objectPos + e.zzx).x +
            e.zzy * ELMap(objectPos + e.zzy).x);
    #else
        // 4-sample tetrahedral normal calculation. Cheaper.
        return normalize(
            e.xyy * ELMap(objectPos + e.xyy).x +
            e.yyx * ELMap(objectPos + e.yyx).x +
            e.yxy * ELMap(objectPos + e.yxy).x +
            e.xxx * ELMap(objectPos + e.xxx).x);
    #endif
}

#ifndef MAX_STEPS
#define MAX_STEPS 200
#endif

#ifndef MIN_DISTANCE
#define MIN_DISTANCE 0.0001
#endif

#ifndef MAX_DISTANCE
#define MAX_DISTANCE 200.0
#endif


bool ELRaymarch(ELRay ray, out float3 objectPos, out float material)
{
    float2 mapResult;

    // to silence warnings about not initialising output values :|
    objectPos = float3(0.0, 0.0, 0.0);
    material = 0.0;

    float3 boxMin;
    float3 boxMax;
    ELBoundingBox(boxMin, boxMax);

    // Fast exit if we don't even hit the bounding box.
    float maxReach;
    if (!ELBoxRayIntersect(boxMin, boxMax, ray, maxReach))
    {
        return false;
    }

    for (uint i = 0; i < MAX_STEPS; i++)
    {
        mapResult = ELMap(ray.position);
        objectPos = ray.position;

        // XXX: Do we even still need MAX_DISTANCE?
        if (mapResult.x > MAX_DISTANCE || ray.reach > maxReach)
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

    // Returning true even when you don't quite reach the surface
    // does make things look better. Big thanks to 1001 for this tip.
    material = mapResult.y;
    return true;
}

#endif // EL_RAYMARCH_COMMON_CGINC_