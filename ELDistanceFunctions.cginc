#ifndef EL_DISTANCE_FUNCTIONS_CGINC
#define EL_DISTANCE_FUNCTIONS_CGINC

#include "UnityCG.cginc"

// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

float2 PolarToCartesian(float r, float theta)
{
    float2 sin_cos;
    sincos(theta, sin_cos[1], sin_cos[0]);
    return sin_cos * r;
}


// SIGNED DISTANCE FUNCTIONS //
// These all return the minimum distance from point p to the desired shape's surface, given the other parameters.
// The result is negative if you are inside the shape.  All shapes are centered about the origin, so you may need to
// transform your input point (p) to account for translation or rotation

// Sphere
// r: radius
float sdSphere(float3 p, float r)
{
    return length(p) - r;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) +
        length(max(d, 0.0));
}

// Torus
// t.x: diameter
// t.y: thickness
float sdTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// Cylinder
// h.x = diameter
// h.y = height
float sdCylinder(float3 p, float2 h)
{
    float2 d = abs(float2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdRoundedCylinder(float3 p, float ra, float rb, float h)
{
    float2 d = float2(length(p.xz) - 2.0 * ra + rb, abs(p.y) - h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
}

float sdCone(float3 p, float2 c)
{
    // c must be normalized
    float q = length(p.xy);
    return dot(c, float2(q, p.z));
}

// (Infinite) Plane
// n.xyz: normal of the plane (normalized).
// n.w: offset
float sdPlane(float3 p, float4 n)
{
    // n must be normalized
    return dot(p, n.xyz) + n.w;
}

float sdHexPrism(float3 p, float2 h)
{
    float3 q = abs(p);
    return max(q.z - h.y, max((q.x*0.866025 + q.y*0.5), q.y) - h.x);
}

float sdTriPrism(float3 p, float2 h)
{
    float3 q = abs(p);
    return max(q.z - h.y, max(q.x*0.866025 + p.y*0.5, -p.y) - h.x*0.5);
}

float sdCapsule(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdCappedCone(in float3 p, in float3 c)
{
    float2 q = float2(length(p.xz), p.y);
    float2 v = float2(c.z*c.y / c.x, -c.z);
    float2 w = v - q;
    float2 vv = float2(dot(v, v), v.x*v.x);
    float2 qv = float2(dot(v, w), v.x*w.x);
    float2 d = max(qv, 0.0)*qv / vv;
    return sqrt(dot(w, w) - max(d.x, d.y))* sign(max(q.y*v.x - q.x*v.y, w.y));
}

float sdEllipsoid(in float3 p, in float3 r)
{
    return (length(p / r) - 1.0) * min(min(r.x, r.y), r.z);
}

// Distance from a point in 2D space to an arc starting at arc_r on the X axis
// and rotating through arc_theta in the positive direction.
float sdArc(float2 p, float arc_r, float arc_theta)
{
    float p_theta = atan2(p.y, p.x);
    if (p_theta < 0.0)
    {
        p_theta += UNITY_TWO_PI;
    }

    if (p_theta >= 0 && p_theta <= arc_theta)
    {
        // Distance to intersection between ray from origin to point and arc
        return abs(length(p) - arc_r);
    }
    else
    {
        // Distance to starting point of arc
        float d1 = length(p - float2(arc_r, 0));
        // Distance to ending point of arc
        float d2 = length(p - PolarToCartesian(arc_r, arc_theta));
        return min(d1, d2);
    }
}

// Distance from a point in 3D space to an arc starting at arc_r on the X axis
// and rotating through arc_theta in the positive direction on the Y axis.
// The thickness of the line can be provided as well at the moment,
// since it ended up commonly used at the caller anyway.
float sdArc(float3 p, float arc_r, float arc_theta, float line_r)
{
    return length(float2(sdArc(p.xy, arc_r, arc_theta), p.z)) - line_r;
}

// BOOLEAN OPERATIONS //
// Apply these operations to multiple "primitive" distance functions to create complex shapes.

// Union
float opU(float d1, float d2)
{
    return min(d1, d2);
}

// Union (with material data)
float2 opU_mat( float2 d1, float2 d2 )
{
    return (d1.x < d2.x) ? d1 : d2;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h); }

// Subtraction
float opS(float d1, float d2)
{
    return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
    return max(d1, d2);
}

// Union (with extra data)
// d1,d2.x: Distance field result
// d1,d2.y: Extra data (material data for example)
float2 opU(float2 d1, float2 d2)
{
    return (d1.x < d2.x) ? d1 : d2;
}

// Intersection (with extra data)
// d1,d2.x: Distance field result
// d1,d2.y: Extra data (material data for example)
float2 opI(float2 d1, float2 d2)
{
    return (d1.x > d2.x) ? d1 : d2;
}

/*
float opScale( in vec3 p, in float s, in sdf3d primitive )
{
    return primitive(p / s) * s;
}
*/

float mod(float x, float y)
{
    return x - y * floor(x / y);
}

float2 pModRotate(float2 p, float a)
{
    return cos(a) * p + sin(a) * float2(p.y, -p.x);
}

float2 pModPolar(float2 p, float repetitions)
{
    float angle = UNITY_TWO_PI / repetitions;
    float r = length(p);
    float a = atan2(p.y, p.x) + angle * 0.5;
    a = mod(a, angle) - angle * 0.5;
    float2 result;
    sincos(a, result.y, result.x);
    return result * r;
}

#endif