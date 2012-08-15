// source:
// http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/

// modified to use rectangle textures

#define RECT_TEXTURE 0

#if RECT_TEXTURE == 0
uniform sampler2D RTBlurH; // this should hold the texture rendered by the horizontal blur pass
#else
uniform sampler2DRect RTBlurH; // this should hold the texture rendered by the horizontal blur pass
#endif
varying vec2 vTexCoord;
uniform vec4 shadowColor;
  
#if RECT_TEXTURE == 0
const float blurSize = 1.0/512.0;

vec4 textureSample(sampler2D texture, vec2 coord)
{
  return texture2D(texture, coord);
}
#else
const float blurSize = 1.0;

vec4 textureSample(sampler2DRect texture, vec2 coord)
{
  return texture2DRect(texture, coord);
}
#endif

void main(void)
{
   vec4 sum = vec4(0.0);
 
   // blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y - 4.0*blurSize)) * 0.05;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y - 3.0*blurSize)) * 0.09;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y - 2.0*blurSize)) * 0.12;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y - blurSize)) * 0.15;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y)) * 0.18; //0.16;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y + blurSize)) * 0.15;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y + 2.0*blurSize)) * 0.12;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y + 3.0*blurSize)) * 0.09;
   sum += textureSample(RTBlurH, vec2(vTexCoord.x, vTexCoord.y + 4.0*blurSize)) * 0.05;
 
   if(shadowColor.a == -1.0)
     gl_FragColor = sum;
   else
     gl_FragColor = vec4(shadowColor.rgb, sum.a * shadowColor.a);
}