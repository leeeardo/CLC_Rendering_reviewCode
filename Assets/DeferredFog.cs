using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[ExecuteInEditMode]
public class DeferredFog : MonoBehaviour
{
    public Shader deferredFog;

    [NonSerialized]
    Material deferredFogMaterial;

    [NonSerialized]
    Camera deferredCamera;

    [NonSerialized]
    Vector3[] frustumCorners;

    [NonSerialized]
    Vector4[] vectorArray;


    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(deferredFogMaterial == null)
        {
            deferredCamera = GetComponent<Camera>();
            frustumCorners = new Vector3[4];
            vectorArray = new Vector4[4];
            deferredFogMaterial = new Material(deferredFog);
        }
        deferredCamera.CalculateFrustumCorners(
            new Rect(0f, 0f, 1f, 1f), deferredCamera.farClipPlane, deferredCamera.stereoActiveEye, frustumCorners);

        vectorArray[0] = frustumCorners[0];
        vectorArray[1] = frustumCorners[3];
        vectorArray[2] = frustumCorners[1];
        vectorArray[3] = frustumCorners[2];
        deferredFogMaterial.SetVectorArray("_FrustumCorners", vectorArray);

        Graphics.Blit(source, destination, deferredFogMaterial);
    }
}
