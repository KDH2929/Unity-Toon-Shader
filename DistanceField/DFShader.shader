Shader "Unlit/DFShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Threshold ("Threshold", Range(0.0, 1.0)) = 0.5
        _EdgeSoftness ("Edge Softness", Range(0.0, 1.0)) = 0.1
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
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

                float distAlphaMask = col.r;        // R채널만 사용해도 되는이유는 그레이스케일이기 때문 (R, G, B 강도는 동일)

                float threshold = clamp(_Threshold, _EdgeSoftness, 1.0 - _EdgeSoftness);        // threshold를 _EdgeSoftness를 더할 때 0~1 사이값이 되도록 clamp 처리
                col.a = smoothstep(threshold - _EdgeSoftness, threshold + _EdgeSoftness, distAlphaMask);

                col.rgb = _Color.rgb;
                col.a *= _Color.a;


                return col;
            }
            ENDCG
        }
    }
}
