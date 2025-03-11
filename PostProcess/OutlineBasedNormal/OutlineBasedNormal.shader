// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/OutlineBasedNormal"
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
            sampler2D _CameraDepthNormalsTexture;
            float4 _MainTex_ST;
            fixed _NormalPower;
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

                float depth;

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


                float3 normalUp, normalDown, normalLeft, normalRight;
                float3 normalUpLeft, normalUpRight, normalDownLeft, normalDownRight;

                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvUp), depth, normalUp);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvDown), depth, normalDown);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvLeft), depth, normalLeft);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvRight), depth, normalRight);

                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvUpLeft), depth, normalUpLeft);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvUpRight), depth, normalUpRight);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvDownLeft), depth, normalDownLeft);
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvDownRight), depth, normalDownRight);


                float3 normal;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), depth, normal);

                // return float4 (normal.xyz, 1);

                float3 NormalOutline = (normalUp - normal) + (normalDown - normal) + (normalLeft - normal) + (normalRight - normal);
                NormalOutline += (normalUpLeft - normal) + (normalUpRight - normal) + (normalDownLeft - normal) + (normalDownRight - normal);

                // return half4(NormalOutline.rgb, 1);

                float Outline = 0;
                float OutlineThreshold = _OutlineThreshold * 10;

                
                if (length(NormalOutline) > OutlineThreshold)
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
