#ifndef EL_RAYCAST_BASE_RAYS_CGINC_
#define EL_RAYCAST_BASE_RAYS_CGINC_

#include "ELRaycastBaseInputOutput.cginc"

/**
 * Structure holding information about a ray.
 */
struct ELRay
{
    /**
     * Origin of the ray.
     */
    float3 start;

    /**
     * Direction of the ray
     */
    float3 dir;

    /**
     * Distance from the origin of the tip of the ray, in units of the length of `dir`.
     */
    float t;

    /**
     * Position of the tip of the ray.
     */
    float3 pos;
};

/**
 * Gets the ray from the camera to the object, from the fragment input structure.
 *
 * @param input the fragment input structure.
 * @return the ray.
 */
ELRay ELGetRay(ELRaycastBaseFragmentInput input)
{
    ELRay ray;
    ray.start = input.objectRayStart;
    ray.dir = normalize(input.objectRayDir);
	ray.t = 0.0;
    ray.pos = ray.start;
    return ray;
}

/**
 * Advances a ray by some amount.
 *
 * @param ray the ray.
 * @param dt the amount to advance, in units of the ray's direction vector.
 */
void ELAdvanceRay(inout ELRay ray, float dt)
{
    ray.t += dt;
    ray.pos = ray.start + ray.dir * ray.t;
}

#endif // EL_RAYCAST_BASE_RAYS_CGINC_