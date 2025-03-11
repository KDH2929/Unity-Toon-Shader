using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GaussianBlurEffect : MonoBehaviour
{
    public Shader curShader;

    [Range(0.0f, 5.0f)]
    public float blurSize = 1.0f;
    private Material screenMat;

    // 프로퍼티
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

    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture)
    {
        if (curShader != null)
        {
            ScreenMat.SetFloat("_BlurSize", blurSize);
            RenderTexture tempTexture = RenderTexture.GetTemporary(sourceTexture.width, sourceTexture.height);
            Graphics.Blit(sourceTexture, tempTexture, ScreenMat);
            Graphics.Blit(tempTexture, destTexture, ScreenMat);
            RenderTexture.ReleaseTemporary(tempTexture);
        }
        else
        {
            Graphics.Blit(sourceTexture, destTexture);
        }
    }

    void Update()
    {
        blurSize = Mathf.Clamp(blurSize, 0.0f, 10.0f);
    }

    void OnDisable()
    {
        if (screenMat)
        {
            DestroyImmediate(screenMat);
        }
    }
}
