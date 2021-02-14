#ifndef EL_VRCHAT_UTILITIES_CGINC_
#define EL_VRCHAT_UTILITIES_CGINC_

#include "UnityCG.cginc"

// Mirror detection courtesy of Merlin

bool ELIsInMirror()
{
    return unity_CameraProjection[2][0] != 0.0 || unity_CameraProjection[2][1] != 0.0;
}

// Camera detection courtesy of ScruffyRuffles

bool ELIsVR()
{
    // USING_STEREO_MATRICES
    #if UNITY_SINGLE_PASS_STEREO
        return true;
    #else
        return false;
    #endif
}

bool ELIsVRHandCamera()
{
    return !ELIsVR() && abs(UNITY_MATRIX_V[0].y) > 0.0000005;
}

bool ELIsDesktop()
{
    return !ELIsVR() && abs(UNITY_MATRIX_V[0].y) < 0.0000005;
}

bool ELIsVRHandCameraPreview()
{
    return ELIsVRHandCamera() && _ScreenParams.y == 720;
}

bool ELIsVRHandCameraPicture()
{
    return ELIsVRHandCamera() && _ScreenParams.y == 1080;
}

bool ELIsPanorama()
{
    // Crude method
    // FOV=90=camproj=[1][1]
    return unity_CameraProjection[1][1] == 1 && _ScreenParams.x == 1075 && _ScreenParams.y == 1025;
}

#endif // EL_VRCHAT_UTILITIES_CGINC_