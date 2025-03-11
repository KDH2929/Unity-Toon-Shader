Shader "Unlit/DFOutlineShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Threshold ("Threshold", Range(0.0, 1.0)) = 0.5
        _EdgeSoftness ("Edge Softness", Range(0.0, 1.0)) = 0.1
        _OutlineThreshold ("Outline Threshold", Range(0.0, 1.0)) = 0.5
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _InnerOutlineValue ("Inner Outline Value", Range(0.0, 1.0)) = 1.0
        _OuterOutlineValue ("Outer Outline Value", Range(0.0, 1.0)) = 0.7
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
            float _Threshold;
            float _EdgeSoftness;
            float _OutlineThreshold;
            fixed4 _OutlineColor;
            float _InnerOutlineValue;
            float _OuterOutlineValue;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);


                float distAlphaMask = col.r; 
   
                float outline = 1.0;
                
                
                // OutlineThreshold를 외곽선으로 설정
                // OutlineThreshold를 기준으로 외곽선 안쪽, 바깥쪽 판단

                // 1 - distAlphaMask를 하면 Distance Field 텍스쳐의 색상값이 반전됨.
                // 바깥쪽으로 갈수록 1로, 안쪽으로 갈수록 0으로 됨

                if (1 - distAlphaMask <= _OutlineThreshold)     // 안쪽으로 갈수록 0이므로 <=가 안쪽영역
                {
                    // InnerOutline 값이 작아질수록 내부영역을 외곽선으로 보는 색상값의 기준점이 낮아짐
                    // 1 - distAlphaMask는 내부로 갈수록 색상값이 0이 됨
                    outline = step(_InnerOutlineValue, 1 - distAlphaMask);      
                }

                else
                { 
                    // OuterOutline 값이 커질수록 1 - _OuterOutlineValue 값은 작아짐 = step함수에서 외곽선으로 판단하는 색상값의 기준점이 낮아짐.
                    // distAlphaMask는 바깥쪽으로 색상값이 갈수록 0이 됨.
                    outline = step(1 - _OuterOutlineValue, distAlphaMask);
                }


                // TEST 중인 코드
                /* 
                if (1 - distAlphaMask <= _OutlineThreshold)
                {
                    outlineFactor = smoothstep(_InnerOutlineValue - _OutlineThreshold, _InnerOutlineValue + _OutlineThreshold, 1 - distAlphaMask);
                }
                else
                {
                    outlineFactor = smoothstep(_OuterOutlineValue + _OutlineThreshold, _OuterOutlineValue - _OutlineThreshold, 1 - distAlphaMask);
                }
                */

                col = lerp(_Color, _OutlineColor, outline);

                // Alpha Test 부분
                float threshold = clamp(_Threshold, _EdgeSoftness, 1.0 - _EdgeSoftness);
                col.a = smoothstep(threshold - _EdgeSoftness, threshold + _EdgeSoftness, distAlphaMask);

                return col;
                
            }
            ENDCG
        }
    }
}
