// source:
// http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/

// modified to use rectangle textures

#define RECT_TEXTURE 0

#if RECT_TEXTURE == 0
uniform sampler2D RTScene; // the texture with the scene you want to blur
#else
uniform sampler2DRect RTScene; // the texture with the scene you want to blur
#endif
varying vec2 vTexCoord;
 
#if RECT_TEXTURE == 0
const float blurSize = 1.0/512.0; // every step will be one pixel wide if the RTScene texture is of size 512x512

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
   sum += textureSample(RTScene, vec2(vTexCoord.x - 4.0*blurSize, vTexCoord.y)) * 0.05;
   sum += textureSample(RTScene, vec2(vTexCoord.x - 3.0*blurSize, vTexCoord.y)) * 0.09;
   sum += textureSample(RTScene, vec2(vTexCoord.x - 2.0*blurSize, vTexCoord.y)) * 0.12;
   sum += textureSample(RTScene, vec2(vTexCoord.x - blurSize, vTexCoord.y)) * 0.15;
   sum += textureSample(RTScene, vec2(vTexCoord.x, vTexCoord.y)) * 0.18; //0.16;
   sum += textureSample(RTScene, vec2(vTexCoord.x + blurSize, vTexCoord.y)) * 0.15;
   sum += textureSample(RTScene, vec2(vTexCoord.x + 2.0*blurSize, vTexCoord.y)) * 0.12;
   sum += textureSample(RTScene, vec2(vTexCoord.x + 3.0*blurSize, vTexCoord.y)) * 0.09;
   sum += textureSample(RTScene, vec2(vTexCoord.x + 4.0*blurSize, vTexCoord.y)) * 0.05;
  
   gl_FragColor = sum;

}
