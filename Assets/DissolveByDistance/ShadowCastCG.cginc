#include "UnityCG.cginc"
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members worldPos)
#pragma exclude_renderers d3d11 xbox360

float4 _Color;
sampler2D _MainTex;
fixed _Cutoff;


struct v2f {
	V2F_SHADOW_CASTER;
	float2 uv : TEXCOORD1;
	float3 worldPos;
};
