Shader "Unlit/OutlineBasedColor"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineThreshold("Outline Threshold", Range(0.0, 1.0)) = 0.5
        _UVOffset("UV Offset", Range(0.0, 10.0)) = 0
        _OutlineColor("Outline Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _OutlineThreshold;
            fixed4 _OutlineColor;
            fixed _UVOffset;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 이동할 오프셋 값
                float2 offset = float2(_UVOffset / _ScreenParams.x, _UVOffset / _ScreenParams.y);

                // 상하좌우로 이동한 UV 좌표
                float2 uvUp = i.uv + float2(0, offset.y);     // 위로 이동
                float2 uvDown = i.uv - float2(0, offset.y);   // 아래로 이동
                float2 uvLeft = i.uv - float2(offset.x, 0);   // 왼쪽으로 이동
                float2 uvRight = i.uv + float2(offset.x, 0);  // 오른쪽으로 이동

                // 대각선으로 이동한 UV 좌표
                float2 uvUpLeft = i.uv - offset;                            // 좌상단으로 이동
                float2 uvUpRight = i.uv + float2(offset.x, -offset.y);  // 우상단으로 이동
                float2 uvDownLeft = i.uv + float2(-offset.x, offset.y); // 좌하단으로 이동
                float2 uvDownRight = i.uv + offset;                      // 우하단으로 이동

                // 이동한 UV 좌표에서 색상 샘플링
                fixed colorUpLeft = tex2D(_MainTex, uvUpLeft).r;
                fixed colorUp = tex2D(_MainTex, uvUp).r;
                fixed colorUpRight = tex2D(_MainTex, uvUpRight).r;
                fixed colorLeft = tex2D(_MainTex, uvLeft).r;
                fixed color = tex2D(_MainTex, i.uv).r;
                fixed colorRight = tex2D(_MainTex, uvRight).r;
                fixed colorDownLeft = tex2D(_MainTex, uvDownLeft).r;
                fixed colorDown = tex2D(_MainTex, uvDown).r;
                fixed colorDownRight = tex2D(_MainTex, uvDownRight).r;

                // Prewitt 필터 기반 수평 방향과 수직 방향 기울기
                float Gx = (
                    colorUpLeft * 1 + colorUp * 1 + colorUpRight * 1 +
                    colorLeft * 0 + color * 0 + colorRight * 0 +
                    colorDownLeft * -1 + colorDown * -1 + colorDownRight * -1
                );

                float Gy = (
                    colorUpLeft * -1 + colorUp * 0 + colorUpRight * 1 +
                    colorLeft * -1 + color * 0 + colorRight * 1 +
                    colorDownLeft * -1 + colorDown * 0 + colorDownRight * 1
                );

                // Manhatten 거리로 근사가능
                float Outline = abs(Gx) + abs(Gy);
                float OutlineThreshold = _OutlineThreshold;

                // 특정 임계치 이상의 값은 외곽선으로 판단하고 그 외의 부분은 외곽선으로 판단하지 않음
                if (Outline > OutlineThreshold)
                {
                    Outline = 1;
                }
                else
                {
                    Outline = 0;
                }

                fixed4 renderTex = tex2D(_MainTex, i.uv);

                // 외곽선 색상 결정
                fixed4 finalColor = lerp(renderTex, _OutlineColor, Outline);

                return finalColor;
            }
            ENDCG
        }
    }
}
