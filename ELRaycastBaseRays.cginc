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
    float3 origin;

    /**
     * Direction of the ray
     */
    float3 direction;

    /**
     * Distance from the origin of the tip of the ray, in units of the length of `dir`.
     */
    float reach;

    /**
     * Position of the tip of the ray.
     */
    float3 position;
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
    ray.origin = input.objectRayOrigin;
    ray.direction = normalize(input.objectRayDirection);
	ray.reach = 0.0;
    ray.position = ray.origin;
    return ray;
}

/**
 * Advances a ray by some amount.
 *
 * @param ray the ray.
 * @param creep the amount to advance, in units of the ray's direction vector.
 */
void ELAdvanceRay(inout ELRay ray, float creep)
{
    ray.reach += creep;
    ray.position = ray.origin + ray.direction * ray.reach;
}

#endif // EL_RAYCAST_BASE_RAYS_CGINC_