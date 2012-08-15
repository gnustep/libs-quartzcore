/* Note:
   Main code of the framework doesn't bind many of the attributes,
   and does not supply any values.
   
   But, it'll have to, on OpenGL ES.
*/

#ifdef GL_ES
/* set default precision for float, vec and mat */
precision highp float;
#endif

#ifdef GL_ES
#define RECT_TEXTURE 0
#else
#define RECT_TEXTURE 0
#endif

#if RECT_TEXTURE == 0
uniform sampler2D texture_2d;
#else
uniform sampler2DRect texture_2drect;
#endif

varying vec4 colorVarying;
#ifdef GL_ES
varying mediump vec2 fragmentTextureCoordinates;
#else
varying vec2 fragmentTextureCoordinates;
#endif


vec2 textureSize(sampler2DRect sampler, int lod)
{
  // function unavailable before GLSL 1.30!
  // 1.30 is unavailable on OS X!
  
  // oh well. hardcoding value 512x512.
  // this function isn't really necessary anyway.
  
  return vec2(512.0, 512.0);
}

void main()
{
  gl_FragColor = colorVarying;
  /* Previous line is unused, apart from eliminating warning
     that colorVarying is unused */
  
  #if RECT_TEXTURE == 0
  gl_FragColor = texture2D(texture_2d, fragmentTextureCoordinates);
  #else
  gl_FragColor = texture2DRect(texture_2drect, fragmentTextureCoordinates);

  //gl_FragColor = texture2DRect(texture_2drect, vec2(textureSize(texture_2drect, 0).x + fragmentTextureCoordinates.x * -1.0, fragmentTextureCoordinates.y));
  #endif
  
}
