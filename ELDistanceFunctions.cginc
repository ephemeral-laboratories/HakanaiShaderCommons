#ifndef EL_DISTANCE_FUNCTIONS_CGINC_
#define EL_DISTANCE_FUNCTIONS_CGINC_

#include "UnityCG.cginc"
#include "ELMathUtilities.cginc"

// Adapted from:
// - http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// - http://mercury.sexy/hg_sdf

float dot2(float2 v)
{
    return dot(v, v);
}
float dot2(float3 v)
{
    return dot(v, v);
}

// SIGNED DISTANCE FUNCTIONS //
// These all return the minimum distance from a position to the desired shape's surface, given the other parameters.
// The result is negative if you are inside the shape.  All shapes are centered about the origin, so you may need to
// transform your input point to account for translation or rotation

// This one's a bit of a tautology but I thought it made sense to have it for completeness.
float udPoint(float2 pos)
{
    return length(pos);
}
float udPoint(float3 pos)
{
    return length(pos);
}

// Sphere
float sdSphere(float3 pos, float radius)
{
    return length(pos) - radius;
}

// Circle in 2D
float sdCircle(float2 pos, float radius)
{
    return length(pos) - radius;
}

// Circle laid down on X-Z plane
float udCircle(float3 pos, float radius)
{
    float l = sdCircle(pos.xz, radius);
    return length(float2(pos.y, l));
}

// Ellipse in 2D
float sdEllipse(float2 pos, float2 ab)
{
    pos = abs(pos);
    if (pos.x > pos.y)
    {
        pos = pos.yx;
        ab = ab.yx;
    }
    float l = ab.y * ab.y - ab.x * ab.x;
    float m = ab.x * pos.x / l;
    float m2 = m * m; 
    float n = ab.y * pos.y / l;
    float n2 = n * n; 
    float c = (m2 + n2 - 1.0) / 3.0;
    float c3 = c * c * c;
    float q = c3 + m2 * n2 * 2.0;
    float d = c3 + m2 * n2;
    float g = m + m * n2;
    float co;
    if (d < 0.0)
    {
        float h = acos(q / c3) / 3.0;
        float s = cos(h);
        float t = sin(h) * sqrt(3.0);
        float rx = sqrt(-c * (s + t + 2.0) + m2);
        float ry = sqrt(-c * (s - t + 2.0) + m2);
        co = (ry + sign(l) * rx + abs(g) / (rx * ry) - m) / 2.0;
    }
    else
    {
        float h = 2.0 * m * n * sqrt(d);
        float s = sign(q + h) * pow(abs(q + h), 1.0 / 3.0);
        float u = sign(q - h) * pow(abs(q - h), 1.0 / 3.0);
        float rx = -s - u - c * 4.0 + 2.0 * m2;
        float ry = (s - u) * sqrt(3.0);
        float rm = sqrt(rx * rx + ry * ry);
        co = (ry / sqrt(rm - rx) + 2.0 * g / rm - m) / 2.0;
    }
    float2 r = ab * float2(co, sqrt(1.0 - co * co));
    return length(r - pos) * sign(pos.y - r.y);
}

// Box
// box: size of box in x/y/z
float sdBox(float3 pos, float3 box)
{
    float3 d = abs(pos) - box;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Box (cheaper - distance to corners is overestimated)
float sdBoxCheap(float3 pos, float3 box)
{
    float3 d = abs(pos) - box;
	return max(d.x, max(d.y, d.z));
}

// Round Box
float sdRoundBox(float3 pos, float3 box, float radius)
{
    return sdBox(pos, box) - radius;
}

// 2D Box
float sdBox2(float2 pos, float2 box)
{
    float2 d = abs(pos) - box;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// 2D Box (cheaper - distance to corners is overestimated)
float fBox2Cheap(float2 pos, float2 box)
{
    float2 d = abs(pos) - box;
	return max(d.x, d.y);
}

// Makes a wireframe box at p with scale b and e is how much to hollow out.
float sdBoundingBox(float3 p, float3 b, float e)
{
    p = abs(p) - b;
    float3 q = abs(p + e) - e;
    return min(min(
        length(max(float3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0),
        length(max(float3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)),
        length(max(float3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0));
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
float sdCone(float3 pos, in float2 c, float h)
{
    // c is the sin/cos of the angle, h is height
    // Alternatively pass q instead of (c,h),
    // which is the point at the base in 2D
    float2 q = h * float2(c.x / c.y, -1.0);

    float2 w = float2(length(pos.xz), pos.y);
    float2 a = w - q * clamp(dot(w, q)/dot(q, q), 0.0, 1.0);
    float2 b = w - q * float2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a),dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
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

float udLineSegment(float2 pos, float2 a, float2 b)
{
	float2 ab = b - a;
	float t = clamp(dot(pos - a, ab) / dot(ab, ab), 0.0, 1.0);
	return length((ab * t + a) - pos);
}
float udLineSegment(float3 pos, float3 a, float3 b)
{
	float3 ab = b - a;
	float t = clamp(dot(pos - a, ab) / dot(ab, ab), 0.0, 1.0);
	return length((ab * t + a) - pos);
}

float sdCapsule(float3 pos, float3 a, float3 b, float r)
{
    return udLineSegment(pos, a, b) - r;
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


//
// "Generalized Distance Functions" by Akleman and Chen.
// see the Paper at https://www.viz.tamu.edu/faculty/ergun/research/implicitmodeling/papers/sm99.pdf
//
// This set of constants is used to construct a large variety of geometric primitives.
// Indices are shifted by 1 compared to the paper because we start counting at Zero.
// Some of those are slow whenever a driver decides to not unroll the loop,
// which seems to happen for fIcosahedron und fTruncatedIcosahedron on nvidia 350.12 at least.
// Specialized implementations can well be faster in all cases.
//

static const float3 GDFVectors[19] = {
	normalize(float3(1.0, 0.0, 0.0)),
	normalize(float3(0.0, 1.0, 0.0)),
	normalize(float3(0.0, 0.0, 1.0)),

	normalize(float3(1.0, 1.0, 1.0)),
	normalize(float3(-1.0, 1.0, 1.0)),
	normalize(float3(1.0, -1.0, 1.0)),
	normalize(float3(1.0, 1.0, -1.0)),

	normalize(float3(0.0, 1.0, EL_PHI + 1.0)),
	normalize(float3(0.0, -1.0, EL_PHI + 1.0)),
	normalize(float3(EL_PHI + 1.0, 0.0, 1.0)),
	normalize(float3(-EL_PHI - 1.0, 0.0, 1.0)),
	normalize(float3(1.0, EL_PHI + 1.0, 0.0)),
	normalize(float3(-1.0, EL_PHI + 1.0, 0.0)),

	normalize(float3(0.0, EL_PHI, 1.0)),
	normalize(float3(0.0, -EL_PHI, 1.0)),
	normalize(float3(1.0, 0.0, EL_PHI)),
	normalize(float3(-1.0, 0.0, EL_PHI)),
	normalize(float3(EL_PHI, 1.0, 0.0)),
	normalize(float3(-EL_PHI, 1.0, 0.0))
};

// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging of objects.
float sdGDF(float3 p, float r, float e, int begin, int end)
{
    float d = 0.0;
    for (int i = begin; i <= end; i++)
    {
        d += pow(abs(dot(p, GDFVectors[i])), e);
    }
    return pow(d, 1.0 / e) - r;
}

// Version with without exponent, creates objects with sharp edges and flat faces
float sdGDF(float3 p, float r, int begin, int end)
{
    float d = 0.0;
    for (int i = begin; i <= end; i++)
    {
        d = max(d, abs(dot(p, GDFVectors[i])));
    }
    return d - r;
}

// Primitives follow:

float sdOctahedron(float3 p, float r, float e)
{
    return sdGDF(p, r, e, 3, 6);
}

float sdDodecahedron(float3 p, float r, float e)
{
    return sdGDF(p, r, e, 13, 18);
}

float sdIcosahedron(float3 p, float r, float e)
{
    return sdGDF(p, r, e, 3, 12);
}

float sdTruncatedOctahedron(float3 p, float r, float e)
{
    return sdGDF(p, r, e, 0, 6);
}

float sdTruncatedIcosahedron(float3 p, float r, float e)
{
    return sdGDF(p, r, e, 3, 18);
}

float sdOctahedron(float3 p, float r)
{
    return sdGDF(p, r, 3, 6);
}

float sdDodecahedron(float3 p, float r)
{
    return sdGDF(p, r, 13, 18);
}

float sdIcosahedron(float3 p, float r)
{
    return sdGDF(p, r, 3, 12);
}

float sdTruncatedOctahedron(float3 p, float r)
{
    return sdGDF(p, r, 0, 6);
}

float sdTruncatedIcosahedron(float3 p, float r)
{
    return sdGDF(p, r, 3, 18);
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

// by pema99 based off of https://swiftcoder.wordpress.com/2010/06/21/logarithmic-spiral-distance-field/
float sdSpiral(float3 p, float thickness, float height, float a, float b, float offset)
{
    const float e = 2.7182;

    // calculate the target radius and theta
    float r = sqrt(p.x * p.x + p.y * p.y);
    float t = atan2(p.y, p.x) + offset;

    // calculate the floating point approximation for n
    float n = (log(r / a) / b - t) / UNITY_TWO_PI;

    // find the two possible radii for the closest point
    float r1 = a * exp(b * (t + UNITY_TWO_PI * ceil(n)));
    float r2 = a * exp(b * (t + UNITY_TWO_PI * floor(n)));
    
    // return the minimum distance to the target point
    float dist = min(abs(r1 - r), abs(r - r2));

    return max(dist / thickness, abs(p.z) - height);
}
float sdKnighty(float3 p, float i0)
{
    const float minsx[5] = {-.3252, -1.05,-1.21,-1.04,-0.737};
    const float minsy[5] = {-.7862, -1.05,-.954,-.79,-0.73};
    const float minsz[5] = {-.0948, -0.0001,-.0001,-.126,-1.23};
    const float minsw[5] = {.678, .7,1.684,.833, .627};
    const float maxsx[5] = {.3457, 1.05,.39,.3457,.73};
    const float maxsy[5] = {1.0218, 1.05,.65,1.0218,0.73};
    const float maxsz[5] = {1.2215, 1.27,1.27,1.2215,.73};
    const float maxsw[5] = {.9834, .95,2.74,.9834, .8335};

    float4 mins = float4(minsx[i0], minsy[i0], minsz[i0], minsw[i0]);
    float4 maxs = float4(maxsx[i0], maxsy[i0], maxsz[i0], maxsw[i0]);

    float k = 0.0;
    float scale=1.0;
    for (int i=0; i < 5; i++)
    {
        p = 2.0 * clamp(p, mins.xyz, maxs.xyz) - p;
        k = max(mins.w / dot(p,p), 1.0);
        p *= k;
        scale *= k;
    }
    float rxy = length(p.xy);
    return 0.7 * max(rxy - maxs.w, rxy * p.z / length(p)) / scale;
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
float udArc(float2 pos, float arc_r, float arc_theta)
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
float udArc(float3 pos, float arc_r, float arc_theta, float line_r)
{
    return length(float2(udArc(pos.xy, arc_r, arc_theta), pos.z)) - line_r;
}

// Bezier curve
float udBezier(float2 pos, float2 A, float2 B, float2 C)
{    
    float2 a = B - A;
    float2 b = A - 2.0 * B + C;
    float2 c = a * 2.0;
    float2 d = A - pos;
    float kk = 1.0 / dot(b, b);
    float kx = kk * dot(a, b);
    float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
    float kz = kk * dot(d, a);
    float res = 0.0;
    float p = ky - kx * kx;
    float p3 = p * p * p;
    float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
    float h = q * q + 4.0 * p3;
    if (h >= 0.0)
    {
        h = sqrt(h);
        float2 x = (float2(h, -h) - q) / 2.0;
        float2 uv = sign(x) * pow(abs(x), 1.0 / 3.0);
        float t = clamp(uv.x + uv.y - kx, 0.0, 1.0);
        res = dot2(d + (c + b * t) * t);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos(q / (p * z * 2.0)) / 3.0;
        float m = cos(v);
        float n = sin(v) * 1.732050808; // sqrt(3)
        float3  t = clamp(float3(m + m, -n - m, n - m) * z - kx, 0.0, 1.0);
        res = min(dot2(d + (c + b * t.x) * t.x),
                  dot2(d + (c + b * t.y) * t.y));
        // the third root cannot be the closest
        // res = min(res, dot2(d + (c + b * t.z) * t.z));
    }
    return sqrt(res);
}


// BOOLEAN OPERATIONS //
// Apply these operations to multiple "primitive" distance functions to create complex shapes.

// Union
float opU(float d1, float d2)
{
    return min(d1, d2);
}
float opU(float d1, float d2, float d3)
{
    return min(d1, min(d2, d3));
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
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
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

void pRotate(inout float2 pos, float theta)
{
	pos = cos(theta) * pos + sin(theta) * float2(pos.y, -pos.x);
}

void pRotateEighth(inout float2 pos)
{
	pos = (pos + float2(pos.y, -pos.x)) * sqrt(0.5);
}

void pRotateQuarter(inout float2 pos)
{
	pos = float2(pos.y, -pos.x);
}

void pRotateBackQuarter(inout float2 pos)
{
	pos = float2(-pos.y, pos.x);
}

void pRotateHalf(inout float2 pos)
{
    pos = -pos;
}

/* I wish.

float pScale(float3 pos, float scale, sdf3d primitive)
{
    return primitive(pos / scale) * scale;
}

*/

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float pos, float size)
{
    float halfsize = size * 0.5;
    float c = floor((pos + halfsize) / size);
    pos = ELMod(pos + halfsize, size) - halfsize;
    return c;
}

// Same, but mirror every second cell so they match at the boundaries
float pModMirror1(inout float pos, float size)
{
    float halfsize = size * 0.5;
    float c = floor((pos + halfsize)/size);
    pos = ELMod(pos + halfsize, size) - halfsize;
    pos *= ELMod(c, 2.0) * 2.0 - 1.0;
    return c;
}

// Repeat the domain only in positive direction. Everything in the negative half-space is unchanged.
float pModSingle1(inout float pos, float size)
{
    float halfsize = size * 0.5;
    float c = floor((pos + halfsize) / size);
    if (pos >= 0)
    {
        pos = ELMod(pos + halfsize, size) - halfsize;
    }
    return c;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(inout float pos, float size, float start, float stop)
{
    float halfsize = size * 0.5;
    float c = floor((pos + halfsize) / size);
    pos = ELMod(pos + halfsize, size) - halfsize;
    if (c > stop) // yes, this might not be the best thing numerically.
    {
        pos += size * (c - stop);
        c = stop;
    }
    if (c < start)
    {
        pos += size * (c - start);
        c = start;
    }
    return c;
}

// Repeat space in two dimensions
float2 pMod2(inout float2 pos, float2 size)
{
    float halfsize = size * 0.5;
    float2 c = floor((pos + halfsize) / size);
    pos = ELMod(pos + halfsize, size) - halfsize;
    return c;
}

// Same, but mirror every second cell so all boundaries match
float2 pModMirror2(inout float2 pos, float2 size)
{
    float2 halfsize = size * 0.5;
    float2 c = floor((pos + halfsize) / size);
    pos = ELMod(pos + halfsize, size) - halfsize;
    pos *= ELMod(c, float2(2.0, 2.0)) * 2.0 - float2(1.0, 1.0);
    return c;
}

// Same, but mirror every second cell at the diagonal as well
float2 pModGrid2(inout float2 pos, float2 size)
{
    float2 halfsize = size * 0.5;
    float2 c = floor((pos + halfsize)/size);
    pos = ELMod(pos + halfsize, size) - halfsize;
    pos *= ELMod(c, float2(2.0, 2.0)) * 2.0 - float2(1.0, 1.0);
    pos -= halfsize;
    if (pos.x > pos.y)
    {
        pos.xy = pos.yx;
    }
    return floor(c * 0.5);
}

// Repeat in three dimensions
float3 pMod3(inout float3 pos, float3 size)
{
    float3 halfsize = size * 0.5;
	float3 c = floor((pos + halfsize) / size);
	pos = ELMod(pos + halfsize, size) - halfsize;
	return c;
}

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