// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Cessna"
{
	Properties
	{
		[HideInInspector] __dirty( "", Int ) = 1
		_Albedocolor("Albedo color", Color) = (0,0,0,0)
		_Cessna("Cessna", 2D) = "white" {}
		_ReflectionProbereflectionHDR("Reflection Probe-reflectionHDR", CUBE) = "white" {}
		_Metalintensity("Metal intensity", Range( 0 , 1)) = 0
		_cessna_normals("cessna_normals", 2D) = "bump" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		_Metalness("Metalness", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldRefl;
			INTERNAL_DATA
		};

		uniform sampler2D _cessna_normals;
		uniform float4 _cessna_normals_ST;
		uniform sampler2D _Cessna;
		uniform float4 _Cessna_ST;
		uniform float4 _Albedocolor;
		uniform samplerCUBE _ReflectionProbereflectionHDR;
		uniform float _Metalintensity;
		uniform float _Metalness;
		uniform float _Smoothness;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_cessna_normals = i.uv_texcoord * _cessna_normals_ST.xy + _cessna_normals_ST.zw;
			o.Normal = lerp( UnpackNormal( tex2D( _cessna_normals,uv_cessna_normals) ) , float3(0,0,1) , 0.7 );
			float2 uv_Cessna = i.uv_texcoord * _Cessna_ST.xy + _Cessna_ST.zw;
			float4 tex2DNode1 = tex2D( _Cessna,uv_Cessna);
			float3 worldrefVec3 = WorldReflectionVector( i , float3(0,0,1) );
			float4 texCUBENode2 = texCUBElod( _ReflectionProbereflectionHDR,float4( worldrefVec3, 4.0));
			o.Albedo = lerp( ( tex2DNode1 * 0.5 ) , ( saturate( ( ( tex2DNode1 * _Albedocolor ) * texCUBENode2 ) )) , _Metalintensity ).rgb;
			o.Emission = ( texCUBENode2 * 0.0 ).xyz;
			o.Metallic = _Metalness;
			o.Smoothness = _Smoothness;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			# include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD6;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				float4 texcoords01 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				fixed3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.texcoords01 = float4( v.texcoord.xy, v.texcoord1.xy );
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			fixed4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.texcoords01.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				fixed3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldRefl = -worldViewDir;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=6001
740;183;1666;974;581.3159;384.4489;1.627473;True;True
Node;AmplifyShaderEditor.RangedFloatNode;5;-876.9,417.3999;Float;False;Constant;_Float0;Float 0;2;0;4;0;0;FLOAT
Node;AmplifyShaderEditor.WorldReflectionVector;3;-861.9,267.3999;Float;False;0;FLOAT3;0,0,0;False;FLOAT3;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.SamplerNode;1;-701.6873,-182.565;Float;True;Property;_Cessna;Cessna;1;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.ColorNode;8;-674.588,30.13515;Float;False;Property;_Albedocolor;Albedo color;0;0;0,0,0,0;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.SamplerNode;2;-607.7491,353.0205;Float;True;Property;_ReflectionProbereflectionHDR;Reflection Probe-reflectionHDR;2;0;None;True;0;False;white;Auto;False;Object;-1;MipLevel;Cube;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;1.0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1.0;False;FLOAT4;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-225.4124,-83.53404;Float;False;0;FLOAT4;0.0,0,0,0;False;1;COLOR;0.0,0,0,0;False;COLOR
Node;AmplifyShaderEditor.RangedFloatNode;12;-164.3934,301.3978;Float;False;Constant;_Float1;Float 1;3;0;0.5;0;0;FLOAT
Node;AmplifyShaderEditor.SamplerNode;32;-81.02352,598.8767;Float;True;Property;_cessna_normals;cessna_normals;4;0;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;FLOAT3;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.Vector3Node;34;-7.723652,796.5765;Float;True;Constant;_Vector0;Vector 0;5;0;0,0,1;FLOAT3;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;31;462.7799,445.2314;Float;False;Constant;_Float2;Float 2;4;0;0;0;0;FLOAT
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;54.98005,182.5306;Float;True;0;FLOAT4;0.0;False;1;FLOAT;0.0,0,0,0;False;FLOAT4
Node;AmplifyShaderEditor.RangedFloatNode;14;-100.6748,425.1176;Float;False;Property;_Metalintensity;Metal intensity;3;0;0;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;37;184.6763,904.4764;Float;False;Constant;_Float3;Float 3;5;0;0.7;0;0;FLOAT
Node;AmplifyShaderEditor.BlendOpsNode;15;12.03959,41.37447;Float;False;Multiply;True;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;COLOR
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;697.1765,328.8765;Float;False;0;FLOAT4;0.0;False;1;FLOAT;0.0,0,0,0;False;FLOAT4
Node;AmplifyShaderEditor.LerpOp;36;317.2764,738.0766;Float;False;0;FLOAT3;0,0,0;False;1;FLOAT3;0.0,0,0;False;2;FLOAT;0.0;False;FLOAT3
Node;AmplifyShaderEditor.RangedFloatNode;39;764.4763,701.6766;Float;False;Property;_Metalness;Metalness;5;0;0;0;1;FLOAT
Node;AmplifyShaderEditor.LerpOp;11;372.7,147.8387;Float;True;0;FLOAT4;0.0;False;1;COLOR;0.0,0,0,0;False;2;FLOAT;0.0;False;COLOR
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-312.9616,117.7074;Float;True;0;FLOAT;0.0;False;1;FLOAT4;0.0;False;FLOAT4
Node;AmplifyShaderEditor.RangedFloatNode;38;773.5763,592.4766;Float;False;Property;_Smoothness;Smoothness;5;0;0;0;1;FLOAT
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1609.1,118.0715;Float;False;True;2;Float;ASEMaterialInspector;Standard;Cessna;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;0;False;0;0;Opaque;0.5;True;True;0;False;Opaque;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;False;0;255;255;0;0;0;0;False;0;4;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;Add;Add;0;False;0;0,0,0,0;VertexOffset;False;Cylindrical;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0.0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;OBJECT;0.0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;13;OBJECT;0.0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False
WireConnection;2;1;3;0
WireConnection;2;2;5;0
WireConnection;7;0;1;0
WireConnection;7;1;8;0
WireConnection;17;0;1;0
WireConnection;17;1;12;0
WireConnection;15;0;7;0
WireConnection;15;1;2;0
WireConnection;30;0;2;0
WireConnection;30;1;31;0
WireConnection;36;0;32;0
WireConnection;36;1;34;0
WireConnection;36;2;37;0
WireConnection;11;0;17;0
WireConnection;11;1;15;0
WireConnection;11;2;14;0
WireConnection;40;0;1;4
WireConnection;40;1;2;0
WireConnection;0;0;11;0
WireConnection;0;1;36;0
WireConnection;0;2;30;0
WireConnection;0;3;39;0
WireConnection;0;4;38;0
ASEEND*/
//CHKSM=6DEA246DE61315AF7072A80F2CAA6397B66D4236