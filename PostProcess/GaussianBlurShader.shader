Shader "Unlit/GaussianBlurShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur Size", Float) = 1.0
    }
    SubShader
    {
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
            float _BlurSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float2 blurSize = float2(_BlurSize / _ScreenParams.x, _BlurSize / _ScreenParams.y);

                // 가우시안 블러 커널 가중치 적용

                fixed4 color = tex2D(_MainTex, uv) * 4.0;
                color += tex2D(_MainTex, uv + float2(blurSize.x, 0.0)) * 2.0;
                color += tex2D(_MainTex, uv - float2(blurSize.x, 0.0)) * 2.0;
                color += tex2D(_MainTex, uv + float2(0.0, blurSize.y)) * 2.0;
                color += tex2D(_MainTex, uv - float2(0.0, blurSize.y)) * 2.0;
                color += tex2D(_MainTex, uv + float2(blurSize.x, blurSize.y)) * 1.0;
                color += tex2D(_MainTex, uv - float2(blurSize.x, blurSize.y)) * 1.0;
                color += tex2D(_MainTex, uv + float2(blurSize.x, -blurSize.y)) * 1.0;
                color += tex2D(_MainTex, uv - float2(blurSize.x, -blurSize.y)) * 1.0;

                color /= 16.0;

                return color;
            }
            ENDCG
        }
    }
}
