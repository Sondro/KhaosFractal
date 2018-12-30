#version 450

uniform vec4 origin;

uniform writeonly image2D destTex;

layout (local_size_x = 16, local_size_y = 16 /*, local_size_z = 1 */) in;

void main() {
	ivec2 storePos = ivec2(gl_GlobalInvocationID.xy);
	vec2 point = (vec2(gl_GlobalInvocationID.x * (1.f / gl_NumWorkGroups.x),
					  gl_GlobalInvocationID.y * (1.f / gl_NumWorkGroups.x))
							* origin.z - (origin.z * .5f)) + origin.xy;
	vec2 x = point.xy;
	float power = origin.w;
	vec4 color = vec4(0.f, 0.f, 0.f, 1.f);
	float radius = 0;
	float r, cis;
	
	for(int i = 1; i<65; ++i)
	{
		// float escape = x.x * x.x + x.y * x.y;
		// x.x = escape * -1.f;
		// x.y = x.x * x.y * 2.f;
		radius = x.x * x.x + x.y * x.y;
		if (radius > 4.f)
		// if (escape > 4.f)
		{
			color = vec4((i % 16) * (1.f / 16.f),
						 (i % 32) * (1.f / 32.f),
						 (i % 64) * (1.f / 64.f), 1.f);
			break;
		}
		// complex number arithmatic z = z^2 + c
		radius = sqrt(radius);
		r = pow(radius, power);
		cis = atan(x.y, x.x);
		x.x = r * cos(power * cis) + point.x;
		x.y = r * sin(power * cis) + point.y;
	}
	imageStore(destTex, storePos, color);
}
