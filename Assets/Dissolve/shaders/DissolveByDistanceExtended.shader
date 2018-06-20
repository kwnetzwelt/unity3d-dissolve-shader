// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Dissolve/Distance/Extended" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5

		[NoScaleOffset] _MetallicGlossMap("Metallic", 2D) = "white" {}
		[Gamma]  _Metallic ("Metallic", Range(0.000000,1.000000)) = 0.000000
		_Center("Dissolve Center", Vector) = (0,0,0)
		_Origin("Line Origin", Vector) = (0,0,0)
		_Target("Line End", Vector) = (0,0,0)
		[Toggle] _FromLine("From Line (as opposed to point)", Float) = 0
		[Toggle] _Reverse("Reverse (hide external)", Float) = 0
		_Distance("Dissolve Distance", Float) = 1
		_Interpolation("Dissolve Interpolation", Range(0,5)) = 1
		_DissTexture("Dissolve Texture", 2D) = "white" {}
		[HDR]_DissolveColor("Dissolve Color", Color) = (0,1,0,1)

		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Normal Influence", Range(0,10)) = 0.5

		[HDR]_EmissionColor ("Color", Color) = (0.000000,0.000000,0.000000,1.000000)
		[NoScaleOffset]_EmissionMap ("Emission", 2D) = "white" { }
	}

	  CGINCLUDE
        //@TODO: should this be pulled into a shader_feature, to be able to turn it off?
        #define _GLOSSYENV 1
        #define UNITY_SETUP_BRDF_INPUT SpecularSetup
    ENDCG
 

		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			// Extracts information for lightmapping, GI (emission, albedo, ...)
			// This pass is not used during regular rendering.
			Pass
			{
				Name "META" 
				Tags { "LightMode"="Meta" }

				Cull Off

				CGPROGRAM
				#pragma vertex vert_meta
				#pragma fragment frag_meta

				#pragma shader_feature _EMISSION
				#pragma shader_feature _METALLICGLOSSMAP

				#include "UnityStandardMeta.cginc"
				ENDCG
			}

			CGPROGRAM

		#include "UnityPBSLighting.cginc"
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard addshadow

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_DissTexture;
			float3 worldPos;
		};

		half _Metallic;
		half _Glossiness;
		sampler2D _MetallicGlossMap;

		sampler2D _EmissionMap;
		float4 _EmissionColor;
		float4 _DissolveColor;

		sampler2D _BumpMap;

		half _Distance;
		half _Interpolation;
		half _BumpScale;


		sampler2D _DissTexture;

		float3 _Center;
		float3 _Origin;
		float3 _Target;
		float _Reverse;
		float _FromLine;

		fixed4 _Color;

		void surf(Input IN, inout SurfaceOutputStandard o) {

			// distance from POINT
			float l_Point = length(IN.worldPos.xyz - _Center.xyz);
			
			// distance from Line
			// http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
			float3 x0 = IN.worldPos.xyz;
			float3 x1 = _Origin;
			float3 x2 = _Target;

			float3 x01 = x0 - x1;
			float3 x02 = x0 - x2;
			float3 x21 = x2 - x1;

			float3 cross0102 = cross(x01, x02);

			float numerator = length(cross0102);
			float denominator = length(x21);

			float l_Line = numerator / denominator;

			float l = _FromLine * l_Line + (1-_FromLine) * l_Point;

			float3 t = tex2D(_DissTexture, IN.uv_DissTexture);
			half d01 = saturate(_Distance);
			float x = (t * _Interpolation * d01);
			
			
			float diff = _Distance - l;
			// Reverse? (0:1) -> -1, 1
			_Reverse = _Reverse * 2 - 1;
			diff = _Reverse * diff;

			// If we are OUT of the line, dont do stuff
			float distanceFromOrigin = length(x01);
			float lineLength = length(x21);
			
			float controlDistance = distanceFromOrigin - lineLength;
			controlDistance = saturate(controlDistance);

			diff += controlDistance * 100;
			
			float final = diff + x;
			float final01 = saturate(final);
			float final01_shifted = final01 - 0.5;

			// final01_shifted = 0;
			// Clips anything AFTER a bit of dissolve
			clip(final01_shifted);

			fixed4 c = tex2D(_MetallicGlossMap, IN.uv_MainTex);
			o.Metallic = c.r * _Metallic ;
			o.Smoothness = _Glossiness * c.a;


			c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;

			o.Normal = normalize(UnpackScaleNormal (tex2D (_BumpMap, IN.uv_BumpMap) , _BumpScale));

			float dL = 0.5 - diff;

			o.Emission = tex2D(_EmissionMap, IN.uv_MainTex) * _EmissionColor + saturate(dL) *_DissolveColor.rgb * tex2D(_DissTexture, IN.uv_DissTexture);
			
			o.Alpha = c.a;
		}
		ENDCG
		}
		Fallback "Diffuse"
}
	
