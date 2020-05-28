#ifndef EL_RAYCAST_FUNCTIONS_CGINC_
#define EL_RAYCAST_FUNCTIONS_CGINC_

/**
 * Performs a sphere-ray intersection check.
 * Coordinates are in object space.
 *
 * @param sphereCentre the centre of the sphere.
 * @param sphereRadius2 the square of the radius of the sphere.
 * @param ray [inout] the ray being cast. The solution is placed into `ray.t`.
 * @return `true` if an intersection is found, `false` otherwise.
 */
bool ELSphereRayIntersect(float3 sphereCentre, float sphereRadius2, inout ELRay ray)
{
    // Solving a quadratic equation
    float a = dot(ray.dir, ray.dir);
    float3 s0_r0 = ray.start - sphereCentre;
    float b = 2.0 * dot(ray.dir, s0_r0);
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

#endif // EL_RAYCAST_FUNCTIONS_CGINC_