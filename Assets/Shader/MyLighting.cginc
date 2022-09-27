// Upgrade NOTE: upgraded instancing buffer 'InstanceProperties' to new syntax.

// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

#ifndef MY_LIGHTINT_INCLUDED
#define MY_LIGHTINT_INCLUDED

    #include "UnityPBSLighting.cginc"
    #include "AutoLight.cginc"

    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        #ifndef FOG_DISTANCE
	        #define FOG_DEPTH 1
        #endif
        #define FOG_ON 1
    #endif

    #if !defined(LIGHTMAP_ON) && defined(SHADOWS_SCREEN)
	    #if defined(SHADOWS_SHADOWMASK) && !defined(UNITY_NO_SCREENSPACE_SHADOWS)
		    #define ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS 1
	    #endif
    #endif

    #if defined(LIGHTMAP_ON) && defined(SHADOWS_SCREEN)
	    #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK)
		    #define SUBTRACTIVE_LIGHTING 1
	    #endif
    #endif

    struct appdata
    {
        UNITY_VERTEX_INPUT_INSTANCE_ID
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;
    };
    struct InterpolatorVertex
    {
        UNITY_VERTEX_INPUT_INSTANCE_ID
        float4 pos : SV_POSITION;
        float4 uv : TEXCOORD0;  
        float3 wNormal : TEXCOORD1;
        float4 wTangent : TEXCOORD2;

        #if FOG_DEPTH
		    float4 wPos : TEXCOORD3;
	    #else
		    float3 wPos : TEXCOORD3;
	    #endif
        UNITY_SHADOW_COORDS(4)

        #if defined(VERTEXLIGHT_ON)
            float3 vertexLightColor : TEXCOORD5;
        #endif
        #if defined(LIGHTMAP_ON)||ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
		    float2 lightmapUV : TEXCOORD5;
	    #endif
        #if defined(DYNAMICLIGHTMAP_ON)
            float2 dynamicLightmapUV : TEXCOORD6;
        #endif

        #if defined(_PARALLAX_MAP)
		    float3 tangentViewDir : TEXCOORD7;
	    #endif
    };


    struct Interpolators
    {
        UNITY_VERTEX_INPUT_INSTANCE_ID
        #if defined(LOD_FADE_CROSSFADE)
            UNITY_VPOS_TYPE vpos : VPOS;
        #else
            float4 pos : SV_POSITION;
        #endif
        float4 uv : TEXCOORD0; 
        float3 wNormal : TEXCOORD1;
        float4 wTangent : TEXCOORD2;

        #if FOG_DEPTH
		    float4 wPos : TEXCOORD3;
	    #else
		    float3 wPos : TEXCOORD3;
	    #endif
        UNITY_SHADOW_COORDS(4)

        #if defined(VERTEXLIGHT_ON)
            float3 vertexLightColor : TEXCOORD5;
        #endif
        #if defined(LIGHTMAP_ON)||ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
		    float2 lightmapUV : TEXCOORD5;
	    #endif
        #if defined(DYNAMICLIGHTMAP_ON)
            float2 dynamicLightmapUV : TEXCOORD6;
        #endif

        #if defined(_PARALLAX_MAP)
		    float3 tangentViewDir : TEXCOORD7;
	    #endif
    };

    sampler2D _MainTex , _DetailTex;

    sampler2D _NormalMap , _DetailNormalMap;
    float _BumpScale , _DetailBumpScale ;
    float4 _MainTex_ST , _DetailTex_ST;

    UNITY_INSTANCING_BUFFER_START(InstanceProperties)
        UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
    #define _Color_arr InstanceProperties
    UNITY_INSTANCING_BUFFER_END(InstanceProperties)
    
    float _Metallic;
    float _Smoothness;
    sampler2D _MetallicMap;
    sampler2D _EmissionMap;
    float3 _Emission;
    sampler2D _OcclusionMap;
    float _OcclusionStrength;
    sampler2D _DetailMask;
    float _Cutoff;

    sampler2D _ParallaxMap;
    float _ParallaxStrength;


    void ComputeVertexLightColor(inout Interpolators i )
{
    #if defined(VERTEXLIGHT_ON)
        i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.wPos, i.wNormal
		);
    #endif
}

    InterpolatorVertex vert (appdata v)
    {
        InterpolatorVertex o;
        UNITY_INITIALIZE_OUTPUT(Interpolators, o);
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v,o);
        o.pos = UnityObjectToClipPos(v.vertex);

        UNITY_TRANSFER_SHADOW(o,v.uv1);


        o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

        #if defined(LIGHTMAP_ON)||ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
		    o.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
	    #endif
         #if defined(DYNAMICLIGHTMAP_ON)
            o.dynamicLightmapUV = 
                v.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
        #endif


        o.wNormal = UnityObjectToWorldNormal(v.normal);
        o.wPos.xyz = mul(unity_ObjectToWorld,v.vertex);
        #if FOG_DEPTH
            o.wPos.w = o.pos.z;
        #endif
        o.wTangent = float4(UnityObjectToWorldDir(v.tangent.xyz),v.tangent.w);
        ComputeVertexLightColor(o);

        #if defined(_PARALLAX_MAP)
            #if defined(PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING)
			    v.tangent.xyz = normalize(v.tangent.xyz);
			    v.normal = normalize(v.normal);
		    #endif
		    float3x3 objectToTangent = 
                float3x3(v.tangent.xyz,cross(v.normal,v.tangent.xyz)*v.tangent.w,v.normal);
            o.tangentViewDir = mul(objectToTangent,ObjSpaceViewDir(v.vertex));
	    #endif

        return o;
    }

    
    float GetDetailMask(Interpolators i){
        #if defined(_DETAIL_MASK)
            return tex2D(_DetailMask,i.uv.xy).a;
        #else
            return 1;
        #endif
    }

    float3 GetAlbedo (Interpolators i){
        float3 albedo = tex2D(_MainTex,i.uv.xy).rgb*UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color).rgb;
        #if defined (_DETAIL_ALBEDO_MAP)
            float3 details = tex2D(_DetailTex,i.uv.zw)*unity_ColorSpaceDouble;
            albedo = lerp(albedo , albedo * details , GetDetailMask(i));
        #endif
        return albedo;
    }

    float3 GetTangentSpaceNormal (Interpolators i)
    {
        float3 normal = float3(0,0,1);
        #if defined(_NORMAL_MAP)
            normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
        #endif
        #if defined(_DETAIL_NORMAL_MAP)
            float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
            detailNormal = lerp(float3(0,0,1) , detailNormal , GetDetailMask(i));
            normal = BlendNormals(normal, detailNormal);
        #endif
        return normal;
    }

    void InitializeFragmentNormal(inout Interpolators i)
    {
        
        float3 tNormal = GetTangentSpaceNormal(i);
        float3 wBinormal = cross(i.wNormal,i.wTangent.xyz)*i.wTangent.w*unity_WorldTransformParams.w;
        float3 newNormal = normalize(mul(i.wTangent.xyz,tNormal.x)+
                            mul(wBinormal,tNormal.y)+mul(i.wNormal,tNormal.z));
        i.wNormal = normalize(newNormal);
    }

    float GetOcclusion(Interpolators i){
        #if defined(_OCCLUSION_MAP)
            return lerp(1, tex2D(_OcclusionMap , i.uv.xy).g,_OcclusionStrength);
        #else
            return 1;
        #endif
    }
    
    float GetMetallic(Interpolators i){
        #if defined(_METALLIC_MAP)
            return tex2D(_MetallicMap , i.uv.xy).r;
        #else
            return _Metallic;
        #endif
    }

    float GetSmoothness (Interpolators i) {
        float smoothness = 1;
	    #if defined(_SMOOTHNESS_ALBEDO)
		    smoothness = tex2D(_MainTex , i.uv.xy).a;
        #elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
            smoothness = tex2D(_MetallicMap,i.uv.xy).a;
        #endif
		    return smoothness * _Smoothness;
    }
    float3 GetEmission (Interpolators i) {
	    #if defined(FORWARD_BASE_PASS)|| defined(DEFERRED_PASS)
		    #if defined(_EMISSION_MAP)
			    return tex2D(_EmissionMap, i.uv.xy) * _Emission;
		    #else
			    return _Emission;
		    #endif
	    #else
		    return 0;
	    #endif
    }
    float GetAlpha (Interpolators i) {
        float alpha = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color).a;
        #ifndef _SMOOTHNESS_ALBEDO
            alpha *= tex2D(_MainTex, i.uv.xy).a;
        #endif
	    return alpha;
    }

    float4 ApplyFog(float4 color , Interpolators i) 
    {
        #if FOG_ON
            float viewDistance = length(_WorldSpaceCameraPos.xyz - i.wPos.xyz);
            #if FOG_DEPTH
		        viewDistance = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.wPos.w);
	        #endif
            UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
            float3 fogColor = 0;
            #ifdef FORWARD_BASE_PASS
                fogColor = unity_FogColor.rgb;
            #endif
            color.rgb = lerp(fogColor,color.rgb,saturate(unityFogFactor));
        #endif
        return color;
    }

    float FadeShadows (Interpolators i , float attenuation)
    {
        #if HANDLE_SHADOWS_BLENDING_IN_GI||ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
            #if ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
                attenuation = SHADOW_ATTENUATION(i);
            #endif
            float viewZ = 
                dot(_WorldSpaceCameraPos-i.wPos,UNITY_MATRIX_V[2].xyz);
            float shadowFadeDistance =
			        UnityComputeShadowFadeDistance(i.wPos, viewZ);
            float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
            float bakeAttenuation =
                UnitySampleBakedOcclusion(i.lightmapUV,i.wPos);
            //attenuation = saturate(attenuation + shadowFade);
            attenuation = UnityMixRealtimeAndBakedShadows(
                attenuation,bakeAttenuation,shadowFade);
        #endif
        return attenuation;
    }

    float GetParallaxHeight (float2 uv) {
	    return tex2D(_ParallaxMap, uv).g;
    }

    float2 ParallaxOffset (float2 uv, float2 viewDir) {
	    float height = GetParallaxHeight(uv);
	    height -= 0.5;
	    height *= _ParallaxStrength;
	    return viewDir * height;
    }

    float2 ParallaxRaymarching(float2 uv , float2 viewDir)
    {
        #if !defined(PARALLAX_RAYMARCHING_STEPS)
		    #define PARALLAX_RAYMARCHING_STEPS 10
	    #endif
        float2 uvOffset = 0;
	    float stepSize = 1.0/PARALLAX_RAYMARCHING_STEPS;
	    float2 uvDelta = viewDir * stepSize * _ParallaxStrength;

        float stepHeight = 1;
        float surfaceHeight = GetParallaxHeight(uv);

        float2 prevUVOffset = uvOffset;
	    float prevStepHeight = stepHeight;
	    float prevSurfaceHeight = surfaceHeight;


        for (int i = 1; i < PARALLAX_RAYMARCHING_STEPS && stepHeight > surfaceHeight; i++) {
            prevUVOffset = uvOffset;
		    prevStepHeight = stepHeight;
		    prevSurfaceHeight = surfaceHeight;

		    uvOffset -= uvDelta;
		    stepHeight -= stepSize;
		    surfaceHeight = GetParallaxHeight(uv + uvOffset);
	    }
        #if !defined(PARALLAX_RAYMARCHING_SEARCH_STEPS)
		    #define PARALLAX_RAYMARCHING_SEARCH_STEPS 0
	    #endif
	    #if PARALLAX_RAYMARCHING_SEARCH_STEPS > 0
		    for (int i = 0; i < PARALLAX_RAYMARCHING_SEARCH_STEPS; i++) {
                uvDelta *= 0.5;
			    stepSize *= 0.5;

                if (stepHeight < surfaceHeight) {
				uvOffset += uvDelta;
				stepHeight += stepSize;
			    }
                else{
                    uvOffset -= uvDelta;
			        stepHeight -= stepSize;
                }        
			    surfaceHeight = GetParallaxHeight(uv + uvOffset);
		    }
	    #elif defined(PARALLAX_RAYMARCHING_INTERPOLATE)
            float prevDifference = prevStepHeight - prevSurfaceHeight;
	        float difference = surfaceHeight - stepHeight;
	        float t = prevDifference / (prevDifference + difference);
	        uvOffset = prevUVOffset - uvDelta * t;
        #endif
	    return uvOffset;
    }

    void ApplyParallax(inout Interpolators i)
    {
        #if defined(_PARALLAX_MAP)
            i.tangentViewDir = normalize(i.tangentViewDir);
            #if !defined(PARALLAX_OFFSET_LIMITING)
                #if !defined(PARALLAX_BIAS)
				    #define PARALLAX_BIAS 0.42
			    #endif
                i.tangentViewDir.xy /= (i.tangentViewDir.z +PARALLAX_BIAS);
            #endif
            #if !defined(PARALLAX_FUNCTION)
			    #define PARALLAX_FUNCTION ParallaxOffset
		    #endif
            float2 uvOffset = PARALLAX_FUNCTION(i.uv.xy, i.tangentViewDir.xy);
		    i.uv.xy += uvOffset;
            i.uv.zw += uvOffset * (_DetailTex_ST.xy/_MainTex_ST.xy);
	    #endif
    }


    UnityLight CreateLight(Interpolators i)
    {
        UnityLight light;    

        #if defined(DEFERRED_PASS)||SUBTRACTIVE_LIGHTING
		    light.dir = float3(0, 1, 0);
		    light.color = 0;
	    #else
            #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
		        light.dir = normalize(_WorldSpaceLightPos0.xyz - i.wPos);
	        #else
		        light.dir = _WorldSpaceLightPos0.xyz;
	        #endif
            UNITY_LIGHT_ATTENUATION(attenuation,i,i.wPos);
            attenuation= FadeShadows(i,attenuation);
            //attenuation *= GetOcclusion(i);
            light.color = _LightColor0.rgb * attenuation;
        #endif
        return light;
    }

    float3 BoxProjection(float3 direction , float3 position , float4 cubemapPosition,float3 boxMin , float3 boxMax)
    {
        #if UNITY_SPECCUBE_BOX_PROJECTION
            UNITY_BRANCH
            if(cubemapPosition.w>0)
            {  
                float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
                float scalar = min(min(factors.x, factors.y), factors.z);
                direction = direction*scalar +(position - cubemapPosition);
            }
        #endif
        return direction;
    }
    void ApplySubtractiveLighting(Interpolators i,inout UnityIndirect indirectLight)
    {
        #if SUBTRACTIVE_LIGHTING
            UNITY_LIGHT_ATTENUATION(attenuation,i,i.wPos.xyz);
            attenuation = FadeShadows(i,attenuation);

            float ndotl = saturate(dot(i.wNormal,_WorldSpaceLightPos0.xyz));
            float3 shadowLightEstimate = 
                ndotl * (1 - attenuation) * _LightColor0.rgb;
            float subtractedLight = indirectLight.diffuse - shadowLightEstimate;
            subtractedLight = max(subtractedLight, unity_ShadowColor.rgb);
            subtractedLight =
			    lerp(subtractedLight, indirectLight.diffuse, _LightShadowData.x);
            //indirectLight.diffuse = subtractedLight;
            indirectLight.diffuse = min(subtractedLight, indirectLight.diffuse);
        #endif
    }


    UnityIndirect CreateIndirectLight (Interpolators i , float3 viewDir)
    {
	    UnityIndirect indirectLight;
	    indirectLight.diffuse = 0;
	    indirectLight.specular = 0;

	    #if defined(VERTEXLIGHT_ON)
		    indirectLight.diffuse = i.vertexLightColor;
	    #endif
        #if defined(FORWARD_BASE_PASS)|| defined(DEFERRED_PASS)
            #if defined(LIGHTMAP_ON)
                indirectLight.diffuse = 
                    DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lightmapUV));
                #if defined(DIRLIGHTMAP_COMBINED)
                    float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd,unity_Lightmap,i.lightmapUV);
                    indirectLight.diffuse = DecodeDirectionalLightmap(indirectLight.diffuse,lightmapDirection,i.wNormal);
                #endif

                ApplySubtractiveLighting(i,indirectLight);
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
                float3 dynamicLightDiffuse = DecodeRealtimeLightmap(
                    UNITY_SAMPLE_TEX2D(unity_DynamicLightmap,i.dynamicLightmapUV));
                #if defined(DIRLIGHTMAP_COMBINED)
                    float4 dynamicLightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality,unity_DynamicLightmap,i.dynamicLightmapUV);
                    indirectLight.diffuse += DecodeDirectionalLightmap(dynamicLightDiffuse,dynamicLightmapDirection,i.wNormal);
                #else
                    indirectLight.diffuse += dynamicLightDiffuse;
                #endif
            #endif

            #if !defined(LIGHTMAP_ON) && !defined(DYNAMICLIGHTMAP_ON)
                #if UNITY_LIGHT_PROBE_PROXY_VOLUME
                    if (unity_ProbeVolumeParams.x ==1)
                    {
                        indirectLight.diffuse = 
                            SHEvalLinearL0L1_SampleProbeVolume(float4(i.wNormal,1),i.wPos);
                        indirectLight.diffuse = max(0 , indirectLight.diffuse);
                        #if defined(UNITY_COLORSPACE_GAMMA)
                            indirectLight.diffuse = LinearToGammaSpace(indirectLight.diffuse);
                        #endif
                    }
                    else
                    {
                        indirectLight.diffuse += max(0,ShadeSH9(float4(i.wNormal,1)));
                    }
                    
                #else
                    indirectLight.diffuse += max(0,ShadeSH9(float4(i.wNormal,1)));
                #endif
            #endif

            float3 reflectDir = reflect(-viewDir,i.wNormal);
            Unity_GlossyEnvironmentData envData;
		    envData.roughness = 1 - GetSmoothness(i);
		    envData.reflUVW = BoxProjection(
			    reflectDir, i.wPos,
			    unity_SpecCube0_ProbePosition,
			    unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		    );
		    float3 probe0 = Unity_GlossyEnvironment(
			    UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
		        );
            envData.reflUVW = BoxProjection(
			    reflectDir, i.wPos,
			    unity_SpecCube1_ProbePosition,
			    unity_SpecCube1_BoxMin, unity_SpecCube0_BoxMax
		    );
            #if UNITY_SPECCUBE_BLENDING
                float interpolator = unity_SpecCube0_BoxMin.w;
                UNITY_BRANCH
                if(interpolator < 0.99999)
                {
                    float3 probe1 = Unity_GlossyEnvironment(
			            UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), unity_SpecCube1_HDR, envData
		            );
                     indirectLight.specular = lerp(probe1,probe0,interpolator);
                }
                else{
                    indirectLight.specular = probe0;
                }
            #else
                indirectLight.specular = probe0;
            #endif

            float occlusion = GetOcclusion(i);
            indirectLight.diffuse *= occlusion;
            indirectLight.specular *= occlusion;

            #if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
			    indirectLight.specular = 0;
		    #endif

        #endif
	    return indirectLight;
    }


    struct FragmentOutput {
	    #if defined(DEFERRED_PASS)
		    float4 gBuffer0 : SV_Target0;
		    float4 gBuffer1 : SV_Target1;
		    float4 gBuffer2 : SV_Target2;
		    float4 gBuffer3 : SV_Target3;

            #if defined(SHADOWS_SHADOWMASK)&& (UNITY_ALLOWED_MRT_COUNT > 4)
                float4 gBuffer4 : SV_TARGET4;
            #endif
	    #else
		    float4 color : SV_Target;
	    #endif
    };

    FragmentOutput frag (Interpolators i) 
    {
        UNITY_SETUP_INSTANCE_ID(i);
        #if defined(LOD_FADE_CROSSFADE)
            UnityApplyDitherCrossFade(i.vpos);
        #endif

        ApplyParallax(i);

        float alpha = GetAlpha(i);
        #ifdef _RENDERING_CUTOUT
            clip(alpha - _Cutoff);
        #endif

        InitializeFragmentNormal(i);

        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.wPos);
        //float3 reflDir = reflect(-lightDir , i.wNormal);

        float3 specularTint;
        float oneMinusReflectivity;

        float3 albedo = DiffuseAndSpecularFromMetallic(
			GetAlbedo(i), GetMetallic(i), specularTint, oneMinusReflectivity
		);  
        #if defined(_RENDERING_TRANSPARENT)
		    albedo *= alpha;
            alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
	    #endif
         //    #if defined(VERTEXLIGHT_ON)
		       // albedo = i.vertexLightColor;
	        //#endif
         //   return float4(albedo,1);
        float4 color = UNITY_BRDF_PBS(
            albedo,specularTint,oneMinusReflectivity,GetSmoothness(i),i.wNormal,
            viewDir,CreateLight(i),CreateIndirectLight(i,viewDir)
            );
        color.rgb+=GetEmission(i);
        #if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
		    color.a = alpha;
	    #endif
        FragmentOutput output;
	    #if defined(DEFERRED_PASS)
            #if !defined(UNITY_HDR_ON)
			    color.rgb = exp2(-color.rgb);
		    #endif
            output.gBuffer0.rgb = albedo;
		    output.gBuffer0.a = GetOcclusion(i);
            output.gBuffer1.rgb = specularTint;
		    output.gBuffer1.a = GetSmoothness(i);
            output.gBuffer2 = float4(i.wNormal * 0.5 + 0.5, 1);
            output.gBuffer3 = color;//float4(GetEmission(i),1);

            #if defined(SHADOWS_SHADOWMASK)&& (UNITY_ALLOWED_MRT_COUNT > 4)
                float2 shadowUV = 0;
                #if defined(LIGHTMAP_ON)
                    shadowUV = i.lightmapUV;
                #endif
                output.gBuffer4 = UnityGetRawBakedOcclusions(shadowUV,i.wPos.xyz);
            #endif

	    #else
            

		    output.color = ApplyFog(color,i);
	    #endif
        return output;
    }

#endif