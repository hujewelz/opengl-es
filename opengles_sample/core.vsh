attribute vec3 position;
varying vec4 vertexColor;

void main()
{
   gl_Position = vec4(position, 1.0);
   vertexColor = vec4(0.5, 0.0, 0.0, 0.1);
}
