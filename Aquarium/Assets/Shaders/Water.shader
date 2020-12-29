Shader "Custom/Water"
{
    Properties
    {
        //Noise
        NoiseTex("NoiseTexture", 2D) = "white" {}

        //Color and textur of the water
        WaterColor("WaterColor", Color) = (1,1,1,1)

        //Waves
        [Header(Wave 1)]
        WaveSpeed("WaveSpeed", float) = 35.0
        WaveHeight("WaveHeight", Range(0,1)) = 0.4
        _WaveFreq("WaveFrequency", float) = 1.0

        [Header(Wave 2)]
        _WaveSpeed2("WaveSpeed 2", float) = 35.0
        _WaveFreq2("WaveFrequency 2", float) = 1.0

        _NormalDelta("Normal Delta", Range(0,1)) = 0.1
        _Roughness("Roughness", Range(0,1)) = 0.1


    }
    SubShader
    {
        Tags { "Queue" = "Transparent"}

        GrabPass
        {
            "_CameraOpaqueTexture"
        }

        Pass
        {
            Cull Back

            CGPROGRAM

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "WaterStuff.cginc"

            #pragma vertex vert
            #pragma fragment frag

            //Water
            float4 WaterColor;
            float albedoConstant;

            //Waves
            //Wave1
            sampler2D NoiseTex;
            float4 NoiseTex_TexelSize;
            float WaveSpeed;
            float WaveHeight;
            float _WaveFreq;
            //Wave2
            float _WaveSpeed2;
            float _WaveFreq2;

            float _NormalDelta;
            float _Roughness;
            
            //Camera depth
            sampler2D _CameraDepthTexture;
            sampler2D _CameraOpaqueTexture;

            struct Input
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float4 texCoord : TEXCOORD1;
            };

            struct Output {
                float4 pos : SV_POSITION;
                float4 color : COLOR;
                float4 texCoord : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD2;
                float3 objectCameraPos : TEXCOORD3;
            };

            float2 GetWaveUV(float3 worldPos, float waveFreq, float2 wind) {

                return (worldPos.xz - wind * _Time.y) * waveFreq;
            }
            
            float GetHeightDisplacement(float3 worldPos) {

                float noiseSample1 = tex2DlodBicubic(NoiseTex, float4(GetWaveUV(worldPos, _WaveFreq, float2(1, 0) * WaveSpeed), 0, 0), NoiseTex_TexelSize);
                float noiseSample2 = tex2DlodBicubic(NoiseTex, float4(GetWaveUV(worldPos, _WaveFreq2, float2(-1, 1) * _WaveSpeed2), 0, 0), NoiseTex_TexelSize);

                return ((noiseSample1 - 1.0) + (noiseSample2 - 1.0)) * WaveHeight;
            }

            float3 GetNormal(float3 worldPos, float originalHeight){
                
                float3 pos1 = worldPos + float3(1, 0, 0)*_NormalDelta;
                float3 pos2 = worldPos + float3(0, 0, 1)*_NormalDelta;

                pos1.y = originalHeight + GetHeightDisplacement(pos1);
                pos2.y = originalHeight + GetHeightDisplacement(pos2);

                float3 v1 = pos1 - worldPos;
                float3 v2 = pos2 - worldPos;

                return normalize(cross(v1, v2));
            }

            Output vert(Input input) {

                Output output;

                //Object space --> world space
                float3 worldPos = mul(UNITY_MATRIX_M, input.vertex).xyz;
                
                float originalHeight = worldPos.y;
               
                //The height coordinate we want to manipulate
                worldPos.y += GetHeightDisplacement(worldPos) * input.color.r;

                output.normal = GetNormal(worldPos, originalHeight);

                //Worldspace --> viewspace --> clipspace 
                output.pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));

                output.color = input.color;
                output.worldPos = worldPos;

                //Compute the variables needed to sample screen-space textures in the pixel shader
                output.screenPos = ComputeScreenPos(output.pos);

                // texture coordinates 
                output.texCoord = input.texCoord;

                output.objectCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));


                return output;

            }

            float3 frag(Output input) : COLOR
            {
                float3 worldPos = input.worldPos;
                float3 normal = input.normal;
                float2 screenUv = input.screenPos.xy/input.screenPos.w;
                float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos);

                float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, input.screenPos);
                float depth = LinearEyeDepth(depthSample).r;
                
                //Ögondjup -> världsavstånd
                float dist = depth / abs(dot(viewDir, UNITY_MATRIX_V[2].xyz));
                float3 extinction = lerp(WaterColor, 1, 0); 

                float3 reflection = 0;
                reflection += CubemapReflection(normal, viewDir, _Roughness);
                reflection += SpecularGGX(normal, viewDir, -_WorldSpaceLightPos0, _Roughness) * _LightColor0;

                float3 refraction = tex2Dproj(_CameraOpaqueTexture, input.screenPos).rgb;
                refraction *= extinction;
                
                float reflectance = Fresnel(normal, viewDir) * input.color.g;
                
                //Linearly interpolates between two points
                return lerp(refraction, reflection, reflectance);
            }

            ENDCG
        }
    }
}

