using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class OutlineBasedColor : MonoBehaviour
{
    public Shader curShader;

    [Range(0.0f, 1.0f)]
    public float OutlineThreshold;

    [Range(0.0f, 3.0f)]
    public float UVOffset = 0.05f;
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
        Camera camera = GetComponent<Camera>();
        if (camera != null)
        {
            camera.depthTextureMode |= DepthTextureMode.DepthNormals;
        }

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
