#ifndef EL_RAYCAST_FUNCTIONS_CGINC_
#define EL_RAYCAST_FUNCTIONS_CGINC_

/**
 * Performs a sphere-ray intersection check.
 * Coordinates are in object space.
 *
 * @param sphereCentre the centre of the sphere.
 * @param sphereRadius2 the square of the radius of the sphere.
 * @param ray [inout] the ray being cast. The solution is placed into `ray.reach` if found.
 * @return `true` if an intersection is found, `false` otherwise.
 */
bool ELSphereRayIntersect(float3 sphereCentre, float sphereRadius2, inout ELRay ray)
{
    // Solving a quadratic equation
    float a = dot(ray.direction, ray.direction);
    float3 s0_r0 = ray.origin - sphereCentre;
    float b = 2.0 * dot(ray.direction, s0_r0);
    float c = dot(s0_r0, s0_r0) - sphereRadius2;
    float discriminant = b * b - 4.0 * a* c;
    if (discriminant < 0.0)
    {
        return false;
    }
    else
    {
        // This assumes you're outside the sphere.
        float t = min(-b - sqrt(discriminant), -b + sqrt(discriminant)) / (2.0 * a);
        ELAdvanceRay(ray, t);
        return true;
    }
}

/**
 * Performs an axis-aligned bounding box (AABB)-ray intersection check.
 * Coordinates are in object space.
 *
 * @param boxMin the minimum X-Y-Z coordinates of the box.
 * @param boxMax the maximum X-Y-Z coordinates of the box.
 * @param ray [inout] the ray being cast. The solution is placed into `ray.reach` if found.
 * @param maxReach [out] receives the maximum reach value for which the ray is still inside the box.
 * @return `true` if an intersection is found, `false` otherwise.
 */
bool ELBoxRayIntersect(float3 boxMin, float3 boxMax, inout ELRay ray, out float maxReach)
{
    float3 invDir = rcp(ray.direction);
    float3 tMin = (boxMin - ray.origin) * invDir;
    float3 tMax = (boxMax - ray.origin) * invDir;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    if (tNear > tFar)
    {
        // Doesn't hit the box.
        maxReach = 0.0;
        return false;
    }
    else if (tNear > 0.0)
    {
        // Outside box, start advance from box
        ELAdvanceRay(ray, tNear);
        maxReach = tFar;
        return true;
    }
    else
    {
        // Inside box, start advance from camera
        maxReach = tFar;
        return true;
    }
}

/* TODO: More primitives */

#endif // EL_RAYCAST_FUNCTIONS_CGINC_