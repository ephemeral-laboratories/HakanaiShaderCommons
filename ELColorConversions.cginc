#ifndef EL_COLOR_CONVERSIONS_CGINC_
#define EL_COLOR_CONVERSIONS_CGINC_


half3 ELHUEtoRGB(in half H)
{
    half r = abs(H * 6 - 3) - 1;
    half g = 2 - abs(H * 6 - 2);
    half b = 2 - abs(H * 6 - 4);
    return saturate(half3(r, g, b));
}

half EPSILON = 1e-10;

half3 ELRGBtoHCV(in half3 rgb)
{
    // Based on work by Sam Hocevar and Emil Persson
    half4 p = (rgb.g < rgb.b) ? half4(rgb.bg, -1.0, 2.0/3.0)
                               : half4(rgb.gb, 0.0, -1.0/3.0);
    half4 q = (rgb.r < p.x) ? half4(p.xyw, rgb.r) : half4(rgb.r, p.yzx);
    half c = q.x - min(q.w, q.y);
    half h = abs((q.w - q.y) / (6 * c + EPSILON) + q.z);
    return half3(h, c, q.x);
}

half3 ELHSVtoRGB(in half3 hsv)
{
    half3 rgb = ELHUEtoRGB(hsv.x);
    return ((rgb - 1) * hsv.y + 1) * hsv.z;
}

half3 ELHSLtoRGB(in half3 hsl)
{
    half3 rgb = ELHUEtoRGB(hsl.x);
    half c = (1 - abs(2 * hsl.z - 1)) * hsl.y;
    return (rgb - 0.5) * c + hsl.z;
}

// The weights of RGB contributions to luminance. Should sum to unity.
static const half3 HCY_WEIGHTS = half3(0.299, 0.587, 0.114);

half3 ELHCYtoRGB(in half3 hcy)
{
    half3 rgb = ELHUEtoRGB(hcy.x);
    half z = dot(rgb, HCY_WEIGHTS);
    if (hcy.z < z)
    {
        hcy.y *= hcy.z / z;
    }
    else if (z < 1)
    {
        hcy.y *= (1 - hcy.z) / (1 - z);
    }
    return (rgb - z) * hcy.y + hcy.z;
}

half HCL_GAMMA = 3;
half HCL_Y0 = 100;
half HCL_MAX_L = 0.530454533953517; // == exp(HCL_GAMMA / HCL_Y0) - 0.5
half PI = 3.1415926536;
 
half3 ELHCLtoRGB(in half3 hcl)
{
    half3 rgb = 0;
    if (hcl.z != 0)
    {
        half h = hcl.x;
        half c = hcl.y;
        half l = hcl.z * HCL_MAX_L;
        half q = exp((1 - c / (2 * l)) * (HCL_GAMMA / HCL_Y0));
        half u = (2 * l - c) / (2 * q - 1);
        half v = c / q;
        half t = tan((h + min(frac(2 * h) / 4, frac(-2 * h) / 8)) * PI * 2);
        h *= 6;
        if (h <= 1)
        {
            rgb.r = 1;
            rgb.g = t / (1 + t);
        }
        else if (h <= 2)
        {
            rgb.r = (1 + t) / t;
            rgb.g = 1;
        }
        else if (h <= 3)
        {
            rgb.g = 1;
            rgb.b = 1 + t;
        }
        else if (h <= 4)
        {
            rgb.g = 1 / (1 + t);
            rgb.b = 1;
        }
        else if (h <= 5)
        {
            rgb.r = -1 / t;
            rgb.b = 1;
        }
        else
        {
            rgb.r = 1;
            rgb.b = -t;
        }
        rgb = rgb * v + u;
    }
    return rgb;
}

half3 ELRGBtoHSV(in half3 rgb)
{
    half3 hcv = ELRGBtoHCV(rgb);
    half s = hcv.y / (hcv.z + EPSILON);
    return half3(hcv.x, s, hcv.z);
}

half3 ELRGBtoHSL(in half3 rgb)
{
    half3 hcv = ELRGBtoHCV(rgb);
    half l = hcv.z - hcv.y * 0.5;
    half s = hcv.y / (1 - abs(l * 2 - 1) + EPSILON);
    return half3(hcv.x, s, l);
}

half3 ELRGBtoHCY(in half3 rgb)
{
    // Corrected by David Schaeffer
    half3 hcv = ELRGBtoHCV(rgb);
    half y = dot(rgb, HCY_WEIGHTS);
    half z = dot(ELHUEtoRGB(hcv.x), HCY_WEIGHTS);
    if (y < z)
    {
        hcv.y *= z / (EPSILON + y);
    }
    else
    {
        hcv.y *= (1 - z) / (EPSILON + 1 - y);
    }
    return half3(hcv.x, hcv.y, y);
}

half3 ELRGBtoHCL(in half3 rgb)
{
    half3 hcl;
    half h = 0;
    half u = min(rgb.r, min(rgb.g, rgb.b));
    half v = max(rgb.r, max(rgb.g, rgb.b));
    half q = HCL_GAMMA / HCL_Y0;
    hcl.y = v - u;
    if (hcl.y != 0)
    {
        h = atan2(rgb.g - rgb.b, rgb.r - rgb.g) / PI;
        q *= u / v;
    }
    q = exp(q);
    hcl.x = frac(h / 2 - min(frac(h), frac(-h)) / 6);
    hcl.y *= q;
    hcl.z = lerp(-u, v, q) / (HCL_MAX_L * 2);
    return hcl;
}

#endif
