Shader "Unlit/SobelFilterOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthPower("Depth Power", Range(0, 1)) = 1
        _OutlineThreshold("Outline Threshold", Range(0.0, 1.0)) = 0.5
        _UVOffset("UV Offset", Range(0.0, 10.0)) = 0
        _OutlineColor("Outline Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        // No culling or depth
        // Cull Off ZWrite Off ZTest Always

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
            fixed _DepthPower;
            float _OutlineThreshold;
            fixed4 _OutlineColor;
            fixed _UVOffset;
            sampler2D _CameraDepthTexture;

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
                float2 uvUp = i.uv - float2(0, offset.y);     // 위로 이동
                float2 uvDown = i.uv + float2(0, offset.y);   // 아래로 이동
                float2 uvLeft = i.uv - float2(offset.x, 0);   // 왼쪽으로 이동
                float2 uvRight = i.uv + float2(offset.x, 0);  // 오른쪽으로 이동

                // 대각선으로 이동한 UV 좌표
                float2 uvUpLeft = i.uv - offset;                            // 좌상단으로 이동
                float2 uvUpRight = i.uv + float2(offset.x, -offset.y);  // 우상단으로 이동
                float2 uvDownLeft = i.uv + float2(-offset.x, offset.y); // 좌하단으로 이동
                float2 uvDownRight = i.uv + offset;                      // 우하단으로 이동

                // 각 방향으로 이동한 깊이 값을 샘플링
                float depthUp = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvUp));
                float depthDown = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvDown));
                float depthLeft = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvLeft));
                float depthRight = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvRight));

                float depthUpLeft = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvUpLeft));
                float depthUpRight = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvUpRight));
                float depthDownLeft = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvDownLeft));
                float depthDownRight = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, uvDownRight));

                // 깊이 값을 보정
                depthUp = pow(Linear01Depth(depthUp), _DepthPower);
                depthDown = pow(Linear01Depth(depthDown), _DepthPower);
                depthLeft = pow(Linear01Depth(depthLeft), _DepthPower);
                depthRight = pow(Linear01Depth(depthRight), _DepthPower);

                depthUpLeft = pow(Linear01Depth(depthUpLeft), _DepthPower);
                depthUpRight = pow(Linear01Depth(depthUpRight), _DepthPower);
                depthDownLeft = pow(Linear01Depth(depthDownLeft), _DepthPower);
                depthDownRight = pow(Linear01Depth(depthDownRight), _DepthPower);

                float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv));
                depth = pow(Linear01Depth(depth), _DepthPower);

                // Sobel 필터 기반 수평 방향과 수직 방향 기울기
                
                float Gx = (
                    depthUpLeft * -1 + depthUp * 0 + depthUpRight * 1 +
                    depthLeft * -2 + depth * 0 + depthRight * 2 +
                    depthDownLeft * -1 + depthDown * 0 + depthDownRight * 1
                 );


                float Gy = (
                    depthUpLeft * -1 + depthUp * -2 + depthUpRight * -1 +
                    depthLeft * 0 + depth * 0 + depthRight * 0 +
                    depthDownLeft * 1 + depthDown * 2 + depthDownRight * 1
                 );

                // sqrt(Gx * Gx + Gy * Gy) ≈ abs(Gx) + abs(Gy)     Manhatten 거리로 근사가능
      
                // float Outline =  sqrt(Gx * Gx + Gy * Gy);
                float Outline = abs(Gx) + abs(Gy);

                float OutlineThreshold = _OutlineThreshold * 0.001;

                if(Outline > OutlineThreshold)       // 특정 임계치 이상의 값은 외곽선으로 판단하고 그 외의 부분은 외곽선으로 판단하지 않음
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
