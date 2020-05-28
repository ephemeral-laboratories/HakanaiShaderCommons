#ifndef EL_DISTANCE_FUNCTIONS_CGINC_
#define EL_DISTANCE_FUNCTIONS_CGINC_

#include "UnityCG.cginc"
#include "ELMathUtilities.cginc"

// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

float dot2(float3 v)
{
    return dot(v, v);
}

// SIGNED DISTANCE FUNCTIONS //
// These all return the minimum distance from a position to the desired shape's surface, given the other parameters.
// The result is negative if you are inside the shape.  All shapes are centered about the origin, so you may need to
// transform your input point to account for translation or rotation

// Sphere
float sdSphere(float3 pos, float radius)
{
    return length(pos) - radius;
}

// Box
// box: size of box in x/y/z
float sdBox(float3 pos, float3 box)
{
    float3 d = abs(pos) - box;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Round Box
float sdRoundBox(float3 pos, float3 box, float radius)
{
    return sdBox(pos, box) - radius;
}

// Torus
// torus.x: diameter
// torus.y: thickness
float sdTorus(float3 pos, float2 torus)
{
    float2 q = float2(length(pos.xz) - torus.x, pos.y);
    return length(q) - torus.y;
}

// Capped Torus
float sdCappedTorus(float3 pos, float2 sc, float ra, float rb)
{
    pos.x = abs(pos.x);
    float k = (sc.y * pos.x > sc.x * pos.y) ? dot(pos.xy, sc) : length(pos.xy);
    return sqrt(dot(pos, pos) + ra * ra - 2.0 * ra * k) - rb;
}

// [Chain] Link
float sdLink(float3 pos, float le, float r1, float r2)
{
    float3 q = float3(pos.x, max(abs(pos.y) - le, 0.0), pos.z);
    return length(float2(length(q.xy) - r1, q.z)) - r2;
}

// Infinite Cylinder
float sdCylinder(float3 pos, float3 c)
{
    return length(pos.xz - c.xy) - c.z;
}

// Cylinder
// cylinder.x = diameter
// cylinder.y = height
float sdCylinder(float3 pos, float2 cylinder)
{
    float2 d = abs(float2(length(pos.xz), pos.y)) - cylinder;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Rounded Cylinder
float sdRoundedCylinder(float3 pos, float ra, float rb, float h)
{
    float2 d = float2(length(pos.xz) - 2.0 * ra + rb, abs(pos.y) - h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
}

// Cone
float sdCone(float3 pos, in float2 c, float h )
{
    // c is the sin/cos of the angle, h is height
    // Alternatively pass q instead of (c,h),
    // which is the point at the base in 2D
    float2 q = h * float2(c.x / c.y, -1.0);

    float2 w = float2(length(pos.xz), pos.y);
    float2 a = w - q * clamp(dot(w, q)/dot(q, q), 0.0, 1.0 );
    float2 b = w - q * float2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a),dot(b, b));
    float s = max( k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    return sqrt(d) * sign(s);
}

// Cone Bound (not exact)
float sdConeBound(float3 pos, float2 c)
{
    // c must be normalized
    float q = length(pos.xy);
    return dot(c, float2(q, pos.z));
}

// Capped Cone
float sdCappedCone(in float3 pos, in float3 c)
{
    float2 q = float2(length(pos.xz), pos.y);
    float2 v = float2(c.z * c.y / c.x, -c.z);
    float2 w = v - q;
    float2 vv = float2(dot(v, v), v.x * v.x);
    float2 qv = float2(dot(v, w), v.x * w.x);
    float2 d = max(qv, 0.0) * qv / vv;
    return sqrt(dot(w, w) - max(d.x, d.y))* sign(max(q.y * v.x - q.x * v.y, w.y));
}

// Round Cone
float sdRoundCone(float3 pos, float r1, float r2, float h)
{
    float2 q = float2(length(pos.xz), pos.y);
    
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, float2(-b, a));
    
    if (k < 0.0)
    {
        return length(q) - r1;
    }
    if (k > a * h)
    {
        return length(q - float2(0.0, h)) - r2;
    }
        
    return dot(q, float2(a,b)) - r1;
}

// Infinite Cone
float sdInfiniteCone(float3 pos, float2 c)
{
    // c is the sin/cos of the angle
    float2 q = float2(length(pos.xz), -pos.y);
    float d = length(q - c * max(dot(q, c), 0.0));
    return d * ((q.x * c.y - q.y * c.x < 0.0) ? -1.0 : 1.0);
}

// (Infinite) Plane
// n.xyz: normal of the plane (must be normalized).
// n.w: offset
float sdPlane(float3 pos, float4 n)
{
    return dot(pos, n.xyz) + n.w;
}

float sdHexPrism(float3 pos, float2 h)
{
    float3 q = abs(pos);
    return max(q.z - h.y, max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x);
}

float sdTriPrism(float3 pos, float2 h)
{
    float3 q = abs(pos);
    return max(q.z - h.y, max(q.x * 0.866025 + pos.y * 0.5, -pos.y) - h.x * 0.5);
}

float sdCapsule(float3 pos, float3 a, float3 b, float r)
{
    float3 pa = pos - a;
    float3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdEllipsoid(in float3 pos, in float3 r)
{
    return (length(pos / r) - 1.0) * min(min(r.x, r.y), r.z);
}

// Solid Angle
// c is the sin/cos of the angle
float sdSolidAngle(float3 pos, float2 c, float ra)
{
    float2 q = float2(length(pos.xz), pos.y);
    float l = length(q) - ra;
    float m = length(q - c * clamp(dot(q, c), 0.0, ra));
    return max(l, m * sign(c.y * q.x - c.x * q.y));
}

// Octahedron
float sdOctahedron(float3 pos, float s)
{
    pos = abs(pos);
    float m = pos.x + pos.y + pos.z - s;
    float3 q;
    if (3.0 * pos.x < m)
    {
        q = pos.xyz;
    }
    else if (3.0 * pos.y < m)
    {
        q = pos.yzx;
    }
    else if (3.0 * pos.z < m)
    {
        q = pos.zxy;
    }
    else
    {
        return m * 0.57735027;
    }
    
    float k = clamp(0.5 * (q.z - q.y + s), 0.0, s); 
    return length(float3(q.x, q.y - s + k, q.z - k)); 
}

// Octahedron Bound (not exact)
float sdOctahedronBound(float3 pos, float s)
{
    pos = abs(pos);
    return (pos.x + pos.y + pos.z - s) * 0.57735027;
}

// Tetrahedron
float sdTetrahedron(float3 pos, float h)
{
    float m2 = h * h + 0.25;

    pos.xz = abs(pos.xz);
    pos.xz = (pos.z > pos.x) ? pos.zx : pos.xz;
    pos.xz -= 0.5;

    float3 q = float3(pos.z, h * pos.y - 0.5 * pos.x, h * pos.x + 0.5 * pos.y);

    float s = max(-q.x, 0.0);
    float t = clamp((q.y - 0.5 * pos.z) / (m2 + 0.25), 0.0, 1.0);

    float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);

    float d2 = min(q.y,-q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);

    return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -pos.y));
}

float udTriangle(float3 pos, float3 a, float3 b, float3 c)
{
    float3 ba = b - a;
    float3 pa = pos - a;
    float3 cb = c - b;
    float3 pb = pos - b;
    float3 ac = a - c;
    float3 pc = pos - c;
    float3 nor = cross(ba, ac);

    return sqrt(
        (sign(dot(cross(ba, nor), pa)) +
         sign(dot(cross(cb, nor), pb)) +
         sign(dot(cross(ac, nor), pc)) < 2.0)
        ?
        min(min(
            dot2(ba * clamp(dot(ba, pa) / dot2(ba), 0.0, 1.0) - pa),
            dot2(cb * clamp(dot(cb, pb) / dot2(cb), 0.0, 1.0) - pb)),
            dot2(ac * clamp(dot(ac, pc) / dot2(ac), 0.0, 1.0) - pc))
        :
        dot(nor, pa) * dot(nor, pa) / dot2(nor));
}

float udQuad(float3 pos, float3 a, float3 b, float3 c, float3 d)
{
    float3 ba = b - a;
    float3 pa = pos - a;
    float3 cb = c - b;
    float3 pb = pos - b;
    float3 dc = d - c;
    float3 pc = pos - c;
    float3 ad = a - d;
    float3 pd = pos - d;
    float3 nor = cross(ba, ad);

    return sqrt(
        (sign(dot(cross(ba, nor), pa)) +
         sign(dot(cross(cb, nor), pb)) +
         sign(dot(cross(dc, nor), pc)) +
         sign(dot(cross(ad, nor), pd)) < 3.0)
        ?
        min(min(min(
            dot2(ba * clamp(dot(ba, pa) / dot2(ba), 0.0, 1.0) - pa),
            dot2(cb * clamp(dot(cb, pb) / dot2(cb), 0.0, 1.0) - pb)),
            dot2(dc * clamp(dot(dc, pc) / dot2(dc), 0.0, 1.0) - pc)),
            dot2(ad * clamp(dot(ad, pd) / dot2(ad), 0.0, 1.0) - pd))
        :
        dot(nor, pa) * dot(nor, pa) / dot2(nor));
}

// Distance from a point in 2D space to an arc starting at arc_r on the X axis
// and rotating through arc_theta in the positive direction.
float sdArc(float2 pos, float arc_r, float arc_theta)
{
    float p_theta = atan2(pos.y, pos.x);
    if (p_theta < 0.0)
    {
        p_theta += UNITY_TWO_PI;
    }

    if (p_theta >= 0 && p_theta <= arc_theta)
    {
        // Distance to intersection between ray from origin to point and arc
        return abs(length(pos) - arc_r);
    }
    else
    {
        // Distance to starting point of arc
        float d1 = length(pos - float2(arc_r, 0));
        // Distance to ending point of arc
        float d2 = length(pos - ELPolarToCartesian(arc_r, arc_theta));
        return min(d1, d2);
    }
}

// Distance from a point in 3D space to an arc starting at arc_r on the X axis
// and rotating through arc_theta in the positive direction on the Y axis.
// The thickness of the line can be provided as well at the moment,
// since it ended up commonly used at the caller anyway.
float sdArc(float3 pos, float arc_r, float arc_theta, float line_r)
{
    return length(float2(sdArc(pos.xy, arc_r, arc_theta), pos.z)) - line_r;
}

// BOOLEAN OPERATIONS //
// Apply these operations to multiple "primitive" distance functions to create complex shapes.

// Union
float opU(float d1, float d2)
{
    return min(d1, d2);
}

// Union (with extra data)
// d1,d2.x: Distance field result
// d1,d2.y: Extra data (material data for example)
float2 opU(float2 d1, float2 d2)
{
    return (d1.x < d2.x) ? d1 : d2;
}

float opSmoothUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float opSmoothSubtraction(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0 );
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

float opSmoothIntersection(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) + k * h * (1.0 - h);
}

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

// Intersection (with extra data)
// d1,d2.x: Distance field result
// d1,d2.y: Extra data (material data for example)
float2 opI(float2 d1, float2 d2)
{
    return (d1.x > d2.x) ? d1 : d2;
}

/* I wish.

float opScale(float3 pos, float scale, sdf3d primitive)
{
    return primitive(pos / scale) * scale;
}

*/

float2 pModRotate(float2 pos, float theta)
{
    return cos(theta) * pos + sin(theta) * float2(pos.y, -pos.x);
}

float2 pModPolar(float2 pos, float repetitions)
{
    float angle = UNITY_TWO_PI / repetitions;
    float r = length(pos);
    float a = atan2(pos.y, pos.x) + angle * 0.5;
    a = ELMod(a, angle) - angle * 0.5;
    float2 result;
    sincos(a, result.y, result.x);
    return result * r;
}

#endif // EL_DISTANCE_FUNCTIONS_CGINC_