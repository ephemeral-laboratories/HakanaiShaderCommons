#ifndef EL_UNITY_UTILITIES_CGINC
#define EL_UNITY_UTILITIES_CGINC

#include "ELMathUtilities.cginc"

float3 ELWorldToObjectPos(float3 worldPos)
{
    return mul(unity_WorldToObject, float4(worldPos, 1.0)).xyz;
}

float3 ELWorldToObjectNormal(float3 worldPos)
{
    return mul(unity_WorldToObject, float4(worldPos, 0.0)).xyz;
}

float3 ELObjectToWorldPos(float3 objectPos)
{
    return mul(unity_ObjectToWorld, float4(objectPos, 1.0)).xyz;
}

float3 ELClipToObjectPos(float4 clipPos)
{
    return mul(unity_WorldToObject, mul(ELMatrixInverse(UNITY_MATRIX_VP), clipPos)).xyz;
}

#endif