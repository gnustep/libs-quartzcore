/* Tests/CATransform3D/catransform3d.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: June 2012

   This file is part of QuartzCore.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#if GSIMPL_UNDER_COCOA
#import <GSQuartzCore/AppleSupport.h>
#endif

#import "QuartzCore/CATransform3D.h"
#import "../Testing.h"

#define QC_EXACT_FLOAT_EQUALITY 0

BOOL QCCGFloatsAreEqual(CGFloat a, CGFloat b)
{
#if QC_EXACT_FLOAT_EQUALITY
  return a == b;
#else
  return fabs(b - a) < 0.000001;
#endif
}

BOOL QCCATransform3DsAreEqual(CATransform3D a, CATransform3D b)
{
  for(int i = 0; i < 16; i++)
    {
      if(!QCCGFloatsAreEqual(((CGFloat*)&a)[i], ((CGFloat*)&b)[i]))
        {
          return NO;
        }
    }
  return YES;
}
void QCDebugPrintOfCATransform3D(CATransform3D transform)
{
  printf("    ");
  for(int i = 0; i < 16; i++)
    {
      printf("%g,\t", ((CGFloat*)&transform)[i]);
      if(i % 4 == 3)
        {
          printf("\n    ");
        }
    }
  printf("\n");
}

int main(int argc, char ** argv)
{
  int testsFailed = 0;
  
  CATransform3D anIdentityTransform = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  };

  
  PASS(CATransform3DIsIdentity(CATransform3DIdentity), "identity transform is identity");

  PASS(CATransform3DEqualToTransform(CATransform3DIdentity, CATransform3DIdentity), "identity transform is equaltotransform identity");
  PASS(CATransform3DEqualToTransform(anIdentityTransform, CATransform3DIdentity), "identity transform is equaltotransform another identity");

  ////////////////////

  CATransform3D somewhatOffIdentityTransform = {
    1.0000001, 0, 0, 0,
    0, 1.0000001, 0, 0,
    0, 0, 1.0000001, 0,
    0, 0, 0, 1.0000001
  };

  PASS(!CATransform3DIsIdentity(somewhatOffIdentityTransform), "a bit off transform is not identity");
  PASS(!CATransform3DEqualToTransform(somewhatOffIdentityTransform, CATransform3DIdentity), "a bit off transform is not equaltotransform identity");

  //////////////////////
  
  CATransform3D twoIdentityTransform = {
    2, 0, 0, 0,
    0, 2, 0, 0,
    0, 0, 2, 0,
    0, 0, 0, 2
  };

  PASS(!CATransform3DIsIdentity(twoIdentityTransform), "two times identity transform is not identity");
  PASS(!CATransform3DEqualToTransform(twoIdentityTransform, CATransform3DIdentity), "two times identity transform is not equaltotransform identity");

  //////////////////////

  CATransform3D theTransform;

  memcpy(&theTransform, &CATransform3DIdentity, sizeof(theTransform));
  PASS(CATransform3DIsIdentity(theTransform), "test transform is set up as identity");
  
  //////////////////////

  CATransform3D correctTranslationTransform = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    2, 3, 4, 1
  };
  CATransform3D translationTransform = CATransform3DMakeTranslation(2, 3, 4);

  PASS(QCCATransform3DsAreEqual(translationTransform, correctTranslationTransform), "translation transform correctly constructed");
  
  /////////////////////
  CATransform3D correctTranslatedTransform = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    4, 6, 8, 1
  };

  CATransform3D translatedTransform = CATransform3DTranslate(translationTransform, 2, 3, 4);

  PASS(QCCATransform3DsAreEqual(translatedTransform, correctTranslatedTransform), "translation transform correctly translated");

  ////////////////////////
  
  CATransform3D correctScaleTransform = {
    2, 0, 0, 0,
    0, 3, 0, 0,
    0, 0, 4, 0,
    0, 0, 0, 1
  };

  CATransform3D scaleTransform = CATransform3DMakeScale(2, 3, 4);
  
  PASS(QCCATransform3DsAreEqual(scaleTransform, correctScaleTransform), "scale transform correctly constructed");

  //////////////////////////

  CATransform3D correctScaledTransform = {
    4, 0, 0, 0,
    0, 9, 0, 0,
    0, 0,16, 0,
    0, 0, 0, 1
  };

  CATransform3D scaledTransform = CATransform3DScale(scaleTransform, 2, 3, 4);
  
  PASS(QCCATransform3DsAreEqual(scaledTransform, correctScaledTransform), "scale transform correctly scaled");

  //////////////////////////

  CATransform3D correctScaledTranslateTransform = {
    2, 0, 0, 0,
    0, 3, 0, 0,
    0, 0, 4, 0,
    2, 3, 4, 1
  };

  CATransform3D scaledTranslateTransform = CATransform3DScale(translationTransform, 2, 3, 4);
  
  PASS(QCCATransform3DsAreEqual(scaledTranslateTransform, correctScaledTranslateTransform), "translation transform correctly scaled");

  //////////////////////////

  CATransform3D correctTranslatedScaleTransform = {
    2, 0, 0, 0,
    0, 3, 0, 0,
    0, 0, 4, 0,
    4, 9,16, 1
  };

  CATransform3D translatedScaleTransform = CATransform3DTranslate(scaleTransform, 2, 3, 4);
  
  PASS(QCCATransform3DsAreEqual(translatedScaleTransform, correctTranslatedScaleTransform), "scale transform correctly translated");

  //////////////////////////

  CATransform3D correctTranslateTransformConcatToScaleTransform = {
    2, 0, 0, 0,
    0, 3, 0, 0,
    0, 0, 4, 0,
    2, 3, 4, 1
  };

  CATransform3D translateTransformConcatToScaleTransform = CATransform3DConcat(scaleTransform, translationTransform);
  
  PASS(QCCATransform3DsAreEqual(translateTransformConcatToScaleTransform, correctTranslateTransformConcatToScaleTransform), "translate transform correctly concatenated to scale transform");

  //////////////////////////

  CATransform3D correctRotationXTransform = {
    1, 0, 0, 0,
    0, 0, 1, 0,
    0, -1,0, 0,
    0, 0, 0, 1
  };

  CATransform3D rotationXTransform = CATransform3DMakeRotation(M_PI/2, 1, 0, 0);

  PASS(QCCATransform3DsAreEqual(rotationXTransform, correctRotationXTransform), "rotation around x transform correctly constructed");

  //////////////////////////

  CATransform3D correctRotationYTransform = {
    0, 0,-1, 0,
    0, 1, 0, 0,
    1, 0, 0, 0,
    0, 0, 0, 1
  };

  CATransform3D rotationYTransform = CATransform3DMakeRotation(M_PI/2, 0, 1, 0);

  PASS(QCCATransform3DsAreEqual(rotationYTransform, correctRotationYTransform), "rotation around y transform correctly constructed");

  //////////////////////////

  CATransform3D correctRotationZTransform = {
    0, 1, 0, 0,
    -1,0, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  };

  CATransform3D rotationZTransform = CATransform3DMakeRotation(M_PI/2, 0, 0, 1);

  PASS(QCCATransform3DsAreEqual(rotationZTransform, correctRotationZTransform), "rotation around z transform correctly constructed");

  //////////////////////////

  CATransform3D correctRotationArbitraryTransform = {
    0.333333,	0.910684,	-0.244017,	0,
    -0.244017,	0.333333,	0.910684,	0,
    0.910684,	-0.244017,	0.333333,	0,
    0,		0,		0,		1
  };

  CATransform3D rotationArbitraryTransform = CATransform3DMakeRotation(M_PI/2, 2, 2, 2);

  PASS(QCCATransform3DsAreEqual(rotationArbitraryTransform, correctRotationArbitraryTransform), "rotation around arbitrary axis transform correctly constructed");
  PASS(!CATransform3DEqualToTransform(rotationArbitraryTransform, correctRotationArbitraryTransform), "rotation around arbitrary axis should fail equalToTransform test (precision)");

  //////////////////////////

  PASS(QCCATransform3DsAreEqual(CATransform3DInvert(CATransform3DIdentity), CATransform3DIdentity), "inverted identity matrix is still identity matrix");
  PASS(QCCATransform3DsAreEqual(correctRotationYTransform, CATransform3DInvert(CATransform3DInvert(correctRotationYTransform))), "inversion of inversion of rotationYTransform is rotationYTransform");


  CATransform3D correctInvertOfRotationArbitraryTransform = {
    0.333333,	-0.244017,	0.910684,	-0,	
    0.910684,	0.333333,	-0.244017,	0,	
   -0.244017,	0.910684,	0.333333,	-0,	
   -0,          0,              -0,             1
  };
  
  CATransform3D invertOfRotationArbitraryTransform = CATransform3DInvert(rotationArbitraryTransform);
  PASS(QCCATransform3DsAreEqual(invertOfRotationArbitraryTransform, correctInvertOfRotationArbitraryTransform), "inversion of rotationArbitraryTransform is correct");


  //////////////////////////

  if(testsFailed)
    {
      printf("\7");
    }
  printf("\n\n===== %d tests failed\n\n", testsFailed);

  return testsFailed;
}

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
