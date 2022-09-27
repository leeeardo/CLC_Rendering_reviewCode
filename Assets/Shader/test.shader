Shader "Hidden/test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

             #pragma multi_compile_fog

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex , _CameraDepthTexture;

            float4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                depth = Linear01Depth(depth);
                float viewDistance = depth * _ProjectionParams.z-_ProjectionParams.y;

                UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
				unityFogFactor = saturate(unityFogFactor);

                //float3 sourceColor = tex2D(_MainTex, i.uv).rgb;
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 foggedColor =
					lerp(unity_FogColor.rgb, col, unityFogFactor);

                
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                return float4(foggedColor,1);
            }
            ENDCG
        }
    }
}
