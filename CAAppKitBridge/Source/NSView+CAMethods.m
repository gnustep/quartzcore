/* NSView+CAMethods.m

   Copyright (C) 2018 Free Software Foundation, Inc.

   Author: Stjepan Brkic <stjepanbrkicc@gmail.com>
   Date: June 2018

   This file is part of QuartzCore/CAAppKitBridge.

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

#import "GSCAData.h"
#import "NSView+CAMethods.h"

@implementation NSView (NSViewCAmethods)
- (CALayer*) _gsLayer
{
  if (self->_coreAnimationData != nil)
    {
      GSCAData * GSCAData = self->_coreAnimationData;
      return GSCAData->_layer;
    }
  return nil;
}

- (CARenderer*) _gsRendererTemp
{
  GSCAData * GSCAData = self->_coreAnimationData;
  if (GSCAData == nil)
    {
      NSLog(@"Cannot call _gsAddCARenderer on an NSView instance before calling \
              setWantsLayer");
      return nil;
    }

    return GSCAData->_renderer;
}

- (BOOL) wantsLayer
{
  GSCAData * GSCAData = self->_coreAnimationData;
  if (GSCAData == nil)
    {
      return NO;
    }

  return GSCAData->_wantsLayer;
}

- (void) setWantsLayer:(BOOL)newValue
  {
  if (newValue == NO)
    {
      return;
    }

    [self _gsRecursiveSetWantsLayer: YES];

}

- (void)drawLayer: (CALayer *)layer
        inContext: (CGContextRef)cgContext
{
  float width = [self bounds].size.width;
  float height = [self bounds].size.height;
  NSLog(@"!!!!!!!!!! NSView %@ is called to draw into %p; w %g h %g", NSStringFromSelector(_cmd), cgContext, width, height);
  /* Draw dummy content into the context
  CGRect rect = CGRectMake(50, 50, width/2.0, height/2.0);
  CGContextSetRGBStrokeColor(ctx, 0, 0, 1, 1);
  CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
  CGContextSetLineWidth(ctx, 4.0);
  CGContextStrokeRect(ctx, rect);
  CGContextFillRect(ctx, rect);
  */

  NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort: cgContext
                                                                            flipped: NO];
/*
  OpalSurface *surface = nil; int x = 0, y = 0;
  [[self gState] GSCurrentSurface: &surface :&x :&y];
  if (surface == nil)
    {
      class opalSurface = NSClassFromString(@"OpalSurface");
      [opalSurface
    }*/
  NSLog(@"nsContext is at %p", nsContext);
  NSLog(@"%g %g %g %g", [self frame].origin.x, [self frame].origin.y, [self frame].size.width, [self frame].size.height);
NSLog(@"%g %g %g %g", [self bounds].origin.x, [self bounds].origin.y, [self bounds].size.width, [self bounds].size.height);

  NSGraphicsContext * old = [NSGraphicsContext currentContext];
  [NSGraphicsContext setCurrentContext: nsContext];
  [self displayRectIgnoringOpacity: [self frame]
                         inContext: nsContext];
  /* OpalSurface* */ id *surface = nil;
  int x = 0, y = 0;
  [[nsContext currentGState] GSCurrentSurface: &surface :&x :&y];
  NSRect translatedBounds = [self bounds]; // doesn't help, maybe unnecessary
  translatedBounds.origin.y -= translatedBounds.size.height;
  [surface handleExposeRect: translatedBounds];

  [NSGraphicsContext setCurrentContext: old];

  CGImageRef image = CGBitmapContextCreateImage(cgContext);

  NSMutableData * data = [NSMutableData data];
  CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)data, (CFStringRef)@"public.png", 1, NULL);
  CGImageDestinationAddImage(destination, image, NULL);
  CGImageDestinationFinalize(destination);

  CGImageRelease(image);

  [data writeToFile:@"/tmp/ovojeruzno.png" atomically:YES];

  NSLog(@"!!!!!!!! NSView %@ : COMPLETE drawing into %p", NSStringFromSelector(_cmd), cgContext);
}


- (void) _gsRecursiveSetWantsLayer: (BOOL)isRoot
{
  /* Initialise new GSCAData instance */
  GSCAData * currGSCAData = [[GSCAData alloc] init];
  currGSCAData->_wantsLayer = isRoot;
  currGSCAData->_isRootLayer = isRoot;
  currGSCAData->_layer = [self makeBackingLayer];
  [currGSCAData->_layer retain];
  [currGSCAData->_layer setBounds: NSRectToCGRect([self bounds])];
  [currGSCAData->_layer setDelegate: self]; // set self (NSView) as delegate

  /* Attach GSCAData to self */
  self->_coreAnimationData = currGSCAData;

  if (isRoot == YES)
    {
      currGSCAData->_renderer = [CARenderer rendererWithNSOpenGLContext: [self _gsCreateOpenGLContext]
                                                           options: nil];
      [currGSCAData->_renderer setLayer: currGSCAData->_layer];           // Set root layer
      [currGSCAData->_renderer setBounds: NSRectToCGRect([self bounds])]; // Set bounds
      [currGSCAData->_renderer retain];
    }

  else
    {
      /* Attach our CALayer to its superView CALayer */
      NSView * superView = [self superview];
      if(superView != nil)
        {
          GSCAData * superGSCAData = superView->_coreAnimationData;
          [superGSCAData->_layer addSublayer:currGSCAData->_layer];
        }
    }

  /* Call  recursively on all the subviews */
  for (NSView *currView in [self subviews])
    {
      [currView _gsRecursiveSetWantsLayer: NO];
    }

}

- (BOOL) _gsAddCARenderer: (CARenderer*)customCARenderer 
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  if (currGSCAData == nil)
    {
      NSLog(@"Cannot call _gsAddCARenderer on an NSView instance before calling \
              setWantsLayer");
      return NO;
    }

  if (!currGSCAData->_isRootLayer)
    {
      NSLog(@"Cannot add CARenderer to a non-root layer");
      return NO;
    }
  currGSCAData->_renderer = customCARenderer;
  return YES;
}

- (BOOL) _gsRemoveCARenderer
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  if (currGSCAData == nil)
    {
      NSLog(@"Cannot call _gsRemoveCARenderer on an NSView instance before calling \
              setWantsLayer");
      return NO;
    }
  if (!currGSCAData->_isRootLayer)
    {
      NSLog(@"Cannot remove CARenderer from a non-root layer");
      return NO;
    }
  currGSCAData->_renderer = nil;
  return YES;
}

- (CALayer *) makeBackingLayer
{
  return [CALayer layer];
}

- (NSOpenGLContext*) _gsCreateOpenGLContext
{
  GSCAData *currGSCAData = self->_coreAnimationData;
  if (currGSCAData == nil)
    {
      NSLog(@"Cannot create OpenGL context on an NSView instance before calling \
              setWantsLayer");
      return nil;
    }
  NSOpenGLContext *currGLContext = currGSCAData->_GLContext;
  if (currGLContext == nil)
    {
      NSOpenGLContext *context = [[NSOpenGLContext alloc] 
                                  initWithFormat: [NSOpenGLView defaultPixelFormat]
                                    shareContext: nil];
      ASSIGN(currGLContext, context);
      ASSIGN(currGSCAData->_GLContext, currGLContext);
      [context setView: self];
    }
  return currGLContext;
}

/* TODO(stjepanbrkicc): Implement custom dealloc */

@end
