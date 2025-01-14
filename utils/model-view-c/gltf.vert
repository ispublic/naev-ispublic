const mat4 I = mat4(
   1.0, 0.0, 0.0, 0.0,
   0.0, 1.0, 0.0, 0.0,
   0.0, 0.0, 1.0, 0.0,
   0.0, 0.0, 0.0, 1.0 );
/* Not including math.glsl here because a python script reads this also and
	can't handle include preprocessor. */
const float M_PI        = 3.14159265358979323846;  /* pi */
const float view_angle = -M_PI / 4.0;
const mat4 view = mat4(
      1.0,             0.0,              0.0, 0.0,
      0.0,  cos(view_angle), sin(view_angle), 0.0,
      0.0, -sin(view_angle), cos(view_angle), 0.0,
      0.0,             0.0,              0.0, 1.0 );
uniform mat4 projection       = I;
uniform mat4 shadow_projection= I;
uniform mat4 model            = I;

in vec3 vertex;
in vec3 vertex_normal;
in vec2 vertex_tex0;
out vec3 position;
out vec4 shadow;
out vec3 normal;
out vec2 tex_coord0;
out mat3 normalH;

const mat4 bias = mat4(
      0.5, 0.0, 0.0, 0.0,
      0.0, 0.5, 0.0, 0.0,
      0.0, 0.0, 0.5, 0.0,
      0.5, 0.5, 0.5, 1.0 );

void main (void)
{
   /* Coordinates and position. */
   mat4 H      = view * model;
   vec4 pos    = H * vec4( vertex, 1.0 );
   tex_coord0  = vertex_tex0;

   /* Compute normal vector. */
   normalH     = mat3(H);
   normal      = normalH * vertex_normal;

   /* Position for fragment shader. */
   position    = pos.xyz;
   gl_Position = projection * pos;

   /* Shadows. */
   shadow      = bias * shadow_projection * model * vec4( vertex, 1.0 );
}
