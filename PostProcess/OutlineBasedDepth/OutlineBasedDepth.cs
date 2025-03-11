using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class OutlineBasedDepth : MonoBehaviour
{
    public Shader curShader;


    [Range(0.0f, 1.0f)]
    public float DepthPower = 1.0f;

    [Range(0.0f, 0.5f)]
    public float OutlineThreshold;

    [Range(0.0f, 5.0f)]
    public float UVOffset = 0.01f;
    public Color OutlineColor = Color.black;
    private Material screenMat;

    Material ScreenMat
    {
        get
        {
            if (screenMat == null)
            {
                screenMat = new Material(curShader);
                screenMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return screenMat;
        }
    }

    void Start()
    {
        if (!SystemInfo.supportsImageEffects)
        {
            enabled = false;
            return;
        }

        if (!curShader || !curShader.isSupported)
        {
            enabled = false;
        }
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (curShader != null)
        {
            ScreenMat.SetFloat("_DepthPower", DepthPower);
            ScreenMat.SetFloat("_OutlineThreshold", OutlineThreshold);
            ScreenMat.SetFloat("_UVOffset", UVOffset);
            ScreenMat.SetColor("_OutlineColor", OutlineColor);
            Graphics.Blit(source, destination, ScreenMat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    void Update()
    {
        DepthPower = Mathf.Clamp(DepthPower, 0.0f, 1.0f);
        OutlineThreshold = Mathf.Clamp(OutlineThreshold, 0.0f, 1.0f);
        UVOffset = Mathf.Clamp(UVOffset, 0.0f, 10.0f);
    }

    void OnDisable()
    {
        if (screenMat)
        {
            DestroyImmediate(screenMat);
        }
    }
}
