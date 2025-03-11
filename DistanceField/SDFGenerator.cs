using UnityEngine;
using System.Collections.Generic;

[ExecuteInEditMode]
public class SDFGenerator : MonoBehaviour
{
    public Texture2D sourceTexture;
    public Material targetMaterial;
    public float range = 1.0f;

    void Start()
    {
        Texture2D outlineTexture = GenerateOutlineTexture(sourceTexture, range);
        targetMaterial.SetTexture("_MainTex", outlineTexture);
    }

    Texture2D GenerateOutlineTexture(Texture2D source, float range)
    {
        int width = source.width;
        int height = source.height;
        Texture2D result = new Texture2D(width, height);

        Color[] pixels = source.GetPixels();
        Color[] resultPixels = new Color[width * height];
        List<Vector2> boundaryPixels = new List<Vector2>();         // 경계 픽셀을 저장할 리스트

        // 경계 픽셀 찾기
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                int index = x + y * width;
                Color currentPixel = pixels[index];
                bool isBoundary = false;
                bool hasBlack = false;
                bool hasWhite = false;

                for (int ny = -1; ny <= 1; ny++)
                {
                    for (int nx = -1; nx <= 1; nx++)
                    {
                        if (nx == 0 && ny == 0)
                            continue;

                        int newX = x + nx;
                        int newY = y + ny;

                        if (newX >= 0 && newX < width && newY >= 0 && newY < height)
                        {
                            int neighborIndex = newX + newY * width;
                            Color neighborPixel = pixels[neighborIndex];

                            if (neighborPixel.r > 0.5f)
                                hasWhite = true;
                            else
                                hasBlack = true;
                        }
                    }
                }

                if (hasBlack && hasWhite)
                {
                    isBoundary = true;
                }

                if (isBoundary)
                {
                    boundaryPixels.Add(new Vector2(x, y));     // 경계 픽셀을 리스트에 추가
                }
            }
        }

        // 경계 픽셀의 개수를 출력하여 디버깅
        Debug.Log("Number of boundary pixels: " + boundaryPixels.Count);

        float[] distanceField = new float[width * height];
        for (int i = 0; i < distanceField.Length; i++)
        {
            distanceField[i] = float.MaxValue;
        }

        // 각 경계 픽셀을 기준으로 거리 필드 갱신
        foreach (Vector2 boundaryPixel in boundaryPixels)
        {
            int boundaryX = (int)boundaryPixel.x;
            int boundaryY = (int)boundaryPixel.y;

            for (int y = -Mathf.CeilToInt(range); y <= Mathf.CeilToInt(range); y++)
            {
                for (int x = -Mathf.CeilToInt(range); x <= Mathf.CeilToInt(range); x++)
                {
                    int currentX = boundaryX + x;
                    int currentY = boundaryY + y;

                    if (currentX >= 0 && currentX < width && currentY >= 0 && currentY < height)
                    {
                        float distance = Vector2.Distance(new Vector2(currentX, currentY), boundaryPixel);
                        if (distance <= range)
                        {
                            int index = currentX + currentY * width;
                            if (distance < distanceField[index])
                            {
                                distanceField[index] = distance;
                            }
                        }
                    }
                }
            }
        }

        // 거리 필드를 기반으로 색상 결정
        for (int i = 0; i < distanceField.Length; i++)
        {
            float normalizedDistance = Mathf.Clamp01(distanceField[i] / range);
            if (pixels[i].r < 0.5f)         // 검정 픽셀 (바깥쪽 픽셀)
            {
                resultPixels[i] = Color.Lerp(Color.black, Color.gray, 1.0f - normalizedDistance);
            }
            else                    // 흰색 픽셀 (안쪽 픽셀)
            {
                resultPixels[i] = Color.Lerp(Color.white, Color.gray, 1.0f - normalizedDistance);
            }
        }

        result.SetPixels(resultPixels);
        result.Apply();
        return result;
    }
}
