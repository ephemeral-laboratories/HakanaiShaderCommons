#ifndef EL_COLOR_CONVERSIONS_CGINC_
#define EL_COLOR_CONVERSIONS_CGINC_

#include "UnityCG.cginc"

// Many functions in here sourced from: http://www.chilliant.com/rgb2hsv.html

/**
 * Common code to convert a hue value to RGB.
 *
 * Expected input range is 0..1:
 *    * If h = 0, returns red
 *    * If h = 1/3, returns green
 *    * If h = 2/3, returns blue
 *    * If h = 1, returns red again
 *
 * @param h the hue value.
 * @return the rgb value.
 */
half3 ELHueToRgb(in half h)
{
    half r = abs(h * 6 - 3) - 1;
    half g = 2 - abs(h * 6 - 2);
    half b = 2 - abs(h * 6 - 4);
    return saturate(half3(r, g, b));
}

half EPSILON = 1e-10;

/**
 * Converts RGB to HCV (Hue-Chroma-Value).
 *
 * @param rgb the RGB value.
 * @return the resulting HCV value.
 */
half3 ELRgbToHcv(in half3 rgb)
{
    // Based on work by Sam Hocevar and Emil Persson
    half4 p = (rgb.g < rgb.b) ? half4(rgb.bg, -1.0, 2.0/3.0)
                               : half4(rgb.gb, 0.0, -1.0/3.0);
    half4 q = (rgb.r < p.x) ? half4(p.xyw, rgb.r) : half4(rgb.r, p.yzx);
    half c = q.x - min(q.w, q.y);
    half h = abs((q.w - q.y) / (6 * c + EPSILON) + q.z);
    return half3(h, c, q.x);
}

/**
 * Converts HSV (Hue-Saturation-Value) to RGB.
 *
 * @param hsv the HSV value.
 * @return the resulting RGB value.
 */
half3 ELHsvToRgb(in half3 hsv)
{
    half3 rgb = ELHueToRgb(hsv.x);
    return ((rgb - 1) * hsv.y + 1) * hsv.z;
}

/**
 * Converts HSL (Hue-Saturation-Lightness) to RGB.
 *
 * @param hsv the HSL value.
 * @return the resulting RGB value.
 */
half3 ELHslToRgb(in half3 hsl)
{
    half3 rgb = ELHueToRgb(hsl.x);
    half c = (1 - abs(2 * hsl.z - 1)) * hsl.y;
    return (rgb - 0.5) * c + hsl.z;
}

// The weights of RGB contributions to luminance.
// Should sum to unity.
half3 HCY_WEIGHTS = half3(0.299, 0.587, 0.114);

/**
 * Converts HCY (Hue-Chroma-Luminance) to RGB.
 *
 * @param hcy the HCY value.
 * @return the resulting RGB value.
 */
half3 HCYToRgb(in half3 hcy)
{
    half3 rgb = ELHueToRgb(hcy.x);
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

/**
 * Converts HCL (Hue-Chroma-Luminance) to RGB.
 *
 * @param hcl the HCL value.
 * @return the resulting RGB value.
 */
half3 ELHclToRgb(in half3 hcl)
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
        half t = tan((h + min(frac(2 * h) / 4, frac(-2 * h) / 8)) * UNITY_PI * 2);
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

/**
 * Converts RGB to HSV.
 *
 * @param rgb the RGB value.
 * @return the resulting HSV value.
 */
half3 ELRgbToHsv(in half3 rgb)
{
    half3 hcv = ELRgbToHcv(rgb);
    half s = hcv.y / (hcv.z + EPSILON);
    return half3(hcv.x, s, hcv.z);
}

/**
 * Converts RGB to HSL (Hue-Saturation-Lightness).
 *
 * @param rgb the RGB value.
 * @return the resulting HSL value.
 */
half3 ELRgbToHsl(in half3 rgb)
{
    half3 hcv = ELRgbToHcv(rgb);
    half l = hcv.z - hcv.y * 0.5;
    half s = hcv.y / (1 - abs(l * 2 - 1) + EPSILON);
    return half3(hcv.x, s, l);
}

/**
 * Converts RGB to HCY (Hue-Chroma-Luminance).
 *
 * @param rgb the RGB value.
 * @return the resulting HCY value.
 */
half3 ELRgbToHcy(in half3 rgb)
{
    // Corrected by David Schaeffer
    half3 hcv = ELRgbToHcv(rgb);
    half y = dot(rgb, HCY_WEIGHTS);
    half z = dot(ELHueToRgb(hcv.x), HCY_WEIGHTS);
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

/**
 * Converts RGB to HCL (Hue-Chroma-Luminance).
 *
 * @param rgb the RGB value.
 * @return the resulting HCL value.
 */
half3 ELRgbToHcl(in half3 rgb)
{
    half3 hcl;
    half h = 0;
    half u = min(rgb.r, min(rgb.g, rgb.b));
    half v = max(rgb.r, max(rgb.g, rgb.b));
    half q = HCL_GAMMA / HCL_Y0;
    hcl.y = v - u;
    if (hcl.y != 0)
    {
        h = atan2(rgb.g - rgb.b, rgb.r - rgb.g) / UNITY_PI;
        q *= u / v;
    }
    q = exp(q);
    hcl.x = frac(h / 2 - min(frac(h), frac(-h)) / 6);
    hcl.y *= q;
    hcl.z = lerp(-u, v, q) / (HCL_MAX_L * 2);
    return hcl;
}

/**
 * Helper function to simply hue shift an RGB color.
 *
 * @param rgb the input RGB value.
 * @param shift the hue shift amount (generally 0..1 as that is the range of hues)
 * @return the hue-shifted RGB value.
 */
float3 ELHueShift(in float3 rgb, in float shift)
{ 
    float3 hsv = ELRgbToHsv(rgb);
    hsv.x = frac(hsv.x + shift);
    return ELHsvToRgb(hsv);
} 


#endif // EL_COLOR_CONVERSIONS_CGINC_
