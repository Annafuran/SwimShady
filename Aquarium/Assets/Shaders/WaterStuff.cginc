#ifndef WATER_STUFF_INCLUDED
#define WATER_STUFF_INCLUDED

#define M_PI 3.14159265

//-----------------------------------------------------------------------------------------
// Specular reflection
//-----------------------------------------------------------------------------------------
float SpecularGGX (float3 normal, float3 viewDir, float3 lightDir, float roughness = 0.05)
{
	float3 halfDir = normalize(viewDir + lightDir);
	float  nDotH = dot(normal, halfDir);
	float  a = nDotH * roughness;
	float  k = roughness / ((1.0 - nDotH * nDotH) + a * a);
	return k * k * (1.0 / M_PI);
}

//-----------------------------------------------------------------------------------------
// Cubemap reflection
//-----------------------------------------------------------------------------------------
float3 SpecularReflection (float3 normal, float3 viewDir, float roughness = 0.05)
{
	//beräkna reflektionsvektorn
	float3 reflectionDir = reflect(viewDir, normal);
	//beräkna mipmap-nivån, baserat på roughnessvärdet
	float  mipLevel = roughness * (1.7 - 0.7 * roughness) * 6;
	//sampla inbyggda reflektionstexturen
	float4 reflectionData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDir, mipLevel);
	//Skit i DecodeHDR, den fixar typ om man använder olika plattformar och skit
	return DecodeHDR(reflectionData, unity_SpecCube0_HDR);
}

//-----------------------------------------------------------------------------------------
// Fresnel reflectance
//-----------------------------------------------------------------------------------------
float Fresnel (float3 normal, float3 viewDir, float exponent = 7.7, float f0 = 0.04)
{
	float costh = abs(dot(normal, viewDir));
	return pow(1 - costh, exponent) * (1-f0) + f0;
}

//-----------------------------------------------------------------------------------------
// Schlick's approximation of the Heyney-Greenstein phase function
//-----------------------------------------------------------------------------------------
float PhaseMie (float costh, float g)
{
	g = min(g, 0.9381);
	float k = 1.55*g - 0.55*g*g*g;

	float kcosth = k*costh;

	return (1 - k*k) / ((4 * M_PI) * (1-kcosth) * (1-kcosth));
}

//-----------------------------------------------------------------------------------------
// Cubic interpolation
//-----------------------------------------------------------------------------------------
float4 Cubic (float v)
{
	float4 n = float4(1.0, 2.0, 3.0, 4.0) - v;
	float4 s = n * n * n;
	float x = s.x;
	float y = s.y - 4.0 * s.x;
	float z = s.z - 4.0 * s.y + 6.0 * s.x;
	float w = 6.0 - x - y - z;
	return float4(x, y, z, w) * (1.0/6.0);
}

//-----------------------------------------------------------------------------------------
// Sample a texture with bicubic filtering
//-----------------------------------------------------------------------------------------
float4 tex2DBicubic (sampler2D tex, float2 texCoords, float4 texelSize)
{
	texCoords = texCoords * texelSize.zw - 0.5;

	float2 fxy = frac(texCoords);
	texCoords -= fxy;

	float4 xcubic = Cubic(fxy.x);
	float4 ycubic = Cubic(fxy.y);

	float4 c = texCoords.xxyy + float2(-0.5, +1.5).xyxy;

	float4 s = float4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
	float4 offset = c + float4(xcubic.yw, ycubic.yw) / s;

	offset *= texelSize.xxyy;

	float4 sample0 = tex2D(tex, offset.xz);
	float4 sample1 = tex2D(tex, offset.yz);
	float4 sample2 = tex2D(tex, offset.xw);
	float4 sample3 = tex2D(tex, offset.yw);

	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);

	return lerp( lerp(sample3, sample2, sx), lerp(sample1, sample0, sx), sy);
}

//-----------------------------------------------------------------------------------------
// Same as above, but with LOD coordinates
//-----------------------------------------------------------------------------------------
float4 tex2DlodBicubic (sampler2D tex, float4 texCoords, float4 texelSize)
{
	texCoords.xy = texCoords.xy * texelSize.zw - 0.5;

	float2 fxy = frac(texCoords.xy);
	texCoords.xy -= fxy;

	float4 xcubic = Cubic(fxy.x);
	float4 ycubic = Cubic(fxy.y);

	float4 c = texCoords.xxyy + float2(-0.5, +1.5).xyxy;

	float4 s = float4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
	float4 offset = c + float4(xcubic.yw, ycubic.yw) / s;

	offset *= texelSize.xxyy;

	float4 sample0 = tex2Dlod(tex, float4(offset.xz, texCoords.zw));
	float4 sample1 = tex2Dlod(tex, float4(offset.yz, texCoords.zw));
	float4 sample2 = tex2Dlod(tex, float4(offset.xw, texCoords.zw));
	float4 sample3 = tex2Dlod(tex, float4(offset.yw, texCoords.zw));

	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);

	return lerp( lerp(sample3, sample2, sx), lerp(sample1, sample0, sx), sy);
}


//-----------------------------------------------------------------------------------------
// Ray-box intersection test. Returns the ordered intersections times
//-----------------------------------------------------------------------------------------
float2 RayBoxIntersection (float3 rayStart, float3 rayDir, float3 boxCenter, float3 boxSize)
{
	float tmin, tmax;
	float3 bounds[2] = { boxCenter - boxSize * 0.5, boxCenter + boxSize * 0.5 };
 
	float3 invdir = 1.0f / rayDir;
 
	bool sgn[3] = { invdir.x < 0, invdir.y < 0, invdir.z < 0 };
 
	float tymin, tymax, tzmin, tzmax; 
 
	tmin =  (bounds[sgn[0]].x   - rayStart.x) * invdir.x; 
	tmax =  (bounds[1-sgn[0]].x - rayStart.x) * invdir.x; 
	tymin = (bounds[sgn[1]].y   - rayStart.y) * invdir.y; 
	tymax = (bounds[1-sgn[1]].y - rayStart.y) * invdir.y; 
 
	if ((tmin > tymax) || (tymin > tmax)) 
		return -1;
	if (tymin > tmin) 
		tmin = tymin; 
	if (tymax < tmax) 
		tmax = tymax; 
 
	tzmin = (bounds[sgn[2]].z   - rayStart.z) * invdir.z; 
	tzmax = (bounds[1-sgn[2]].z - rayStart.z) * invdir.z; 
 
	if ((tmin > tzmax) || (tzmin > tmax)) 
		return -1;
	if (tzmin > tmin) 
		tmin = tzmin; 
	if (tzmax < tmax) 
		tmax = tzmax;
 
	if (tmax < 0)
		return -1;
 
	return float2(tmin, tmax);
}

#endif // WATER_STUFF_INCLUDED