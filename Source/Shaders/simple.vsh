/* Note:
   Main code of the framework doesn't bind many of the attributes,
   and does not supply any values.
   
   But, it'll have to, on OpenGL ES.
*/

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texturecoord_2d;
 
uniform mat4 modelViewProjectionMatrix;
varying vec4 colorVarying;
varying vec2 fragmentTextureCoordinates; 

void main()
{
#ifdef GL_ES
  gl_Position = modelViewProjectionMatrix * position;
#else
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
#endif

  colorVarying.xyz = normal;
  /* Previous line is unused, apart from eliminating warning
     that 'normal' is unused */
  colorVarying = color;
#ifdef GL_ES
  fragmentTextureCoordinates = texturecoord_2d;
#else
  fragmentTextureCoordinates = gl_MultiTexCoord0.xy; //gl_TexCoord[0].xy;
  // gl_TexCoord[0]  = gl_MultiTexCoord0;
#endif
}
