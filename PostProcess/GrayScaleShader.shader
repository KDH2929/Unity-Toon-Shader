Shader "Unlit/GrayScaleShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Luminosity("Luminosity", Range(0.0, 1)) = 1.0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            // #pragma vertex vert_img
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
            fixed _Luminosity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                 fixed4 renderTex = tex2D(_MainTex, i.uv);
                 float luminosity = 0.299f * renderTex.r + 0.587f * renderTex.g + 0.114f * renderTex.b;
                 fixed4 finalColor = lerp(renderTex, luminosity, _Luminosity);
                 renderTex.rgb = finalColor;
                 return renderTex;
            }
            ENDCG
        }
    }
}
