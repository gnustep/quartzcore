/* NSView+CAmethods.m

   Copyright (C) 2018 Free Software Foundation, Inc.

   Author: Stjepan Brkic <stjepanbrkicc@gmail.com>
   Date: June 2018

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


#import "CAAppKitBridge/CAData.h"
#import "CAAppKitBridge/NSView+CAmethods.h"
#import <Foundation/Foundation.h>

@implementation NSView (NSViewCAmethods)
- (BOOL) wantsLayer {
    if (self->_coreAnimationData == nil) {
        return NO;
    }
    CAData * cadata = self->_coreAnimationData;
    return cadata->_wantsLayer;
}
- (void) setWantsLayer:(BOOL) newValue{
    if (newValue == NO){
        return;
    }

    /* Initialise new CAData if setWantsLayer:YES */
    CAData * cadata = [[CAData alloc]init];
    cadata->_wantsLayer = YES;
    cadata->_isRootLayer = YES;
    cadata->_layer = [self makeBackingLayer];
    //cadata->_renderer = 
    //    [CARenderer rendererWithNSOpenGLContext: [self openGLContext].CGLContextObj
    //                                                   options: nil];
    /* Attach cadata to self */
    self->_coreAnimationData = cadata;

    /* Further prep of CARenderer */
    [cadata->_renderer setLayer: cadata->_layer]; // Set root layer
    [cadata->_renderer setBounds: NSRectToCGRect([self bounds])]; // Set bounds

    /* Call _recursiveSubviewPropagation recursively on all the subviews */
    for (NSView *currView in [self subviews])
    {
        [currView _recursiveSubviewPropagation];
    }
}

- (void) _recursiveSubviewPropagation {
    /* Initialise new CAData instance */
    CAData * cadata = [[CAData alloc]init];
    cadata->_wantsLayer = NO; // A bit unintuitive, but default Apple behaviour.
    cadata->_isRootLayer = NO;
    cadata->_layer = [self makeBackingLayer];

    /* Attach cadata to self */
    self->_coreAnimationData = cadata;

    /* Attach our CALayer to its superView CALayer */
    NSView * superView = [self superview];
    if(superView != nil){
        CAData * supercadata = superView->_coreAnimationData;
        [supercadata->_layer addSublayer:cadata->_layer];
    }

    /* Call wantsLayer recursively on all the subviews */
    for (NSView *currView in [self subviews])
    {
        [currView _recursiveSubviewPropagation];
    }


}

- (BOOL) addCARenderer: (CARenderer*) customCARenderer {
    CAData *currCAData = self->_coreAnimationData;
    if (!currCAData->_isRootLayer) {
        NSLog(@"Cannot add CARenderer to a non-root layer");
        return NO;
    }
    currCAData->_renderer = customCARenderer;
    return YES;

}

- (BOOL) removeCARenderer {
    CAData *currCAData = self->_coreAnimationData;
    if (!currCAData->_isRootLayer) {
        NSLog(@"Cannot remove CARenderer from a non-root layer");
        return NO;
    }
    currCAData->_renderer = nil;
    return YES;

}

- (CALayer *) makeBackingLayer {
    return [CALayer layer];
}



/* methods from libs-gui/Headers/AppKit/NSOpenGlView.h */

static NSOpenGLPixelFormat *fmt = nil;
static NSOpenGLPixelFormatAttribute attrs[] =
    {   
      NSOpenGLPFADoubleBuffer,
      NSOpenGLPFADepthSize, 16,
      NSOpenGLPFAColorSize, 1,
      0
};

+ (NSOpenGLPixelFormat*) defaultPixelFormat
{
  // Initialize it once

  if (!fmt)
    fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: attrs];

  if (fmt)
    return fmt;

  else
    {
      NSWarnMLog(@"could not find a reasonable pixel format...");
      return nil;
    }


}


/**
   detach from the current context.  You should call it before releasing this 
   object.
 */
- (void) clearGLContext
{
    CAData *currCAData = self->_coreAnimationData;
    NSOpenGLContext *currGlContext = currCAData->_glcontext;
  if (currGlContext)
    {
      [currGlContext clearDrawable];
      DESTROY(currGlContext);
      currCAData->_prepared = NO;
    }
}

- (void) setOpenGLContext: (NSOpenGLContext*)context
{
    CAData *currCAData = self->_coreAnimationData;
    NSOpenGLContext *currGlContext = currCAData->_glcontext;
    if ( context != currGlContext )
        {
        [self clearGLContext];
        ASSIGN(currGlContext, context);
        }
}

- (void) prepareOpenGL
{
}

- (NSOpenGLContext*) openGLContext
{
    CAData *currCAData = self->_coreAnimationData;
    NSOpenGLContext *currGlContext = currCAData->_glcontext;
    if (currGlContext == nil)
    {
      NSOpenGLContext *context = [[NSOpenGLContext alloc] 
                                     initWithFormat: currCAData->_pixel_format
                                     shareContext: nil];

      [self setOpenGLContext: context];
      [context setView: self];

      RELEASE(context);
    }
    return currGlContext;
}


-(id) initWithFrame: (NSRect)frameRect
{  
  return [self initWithFrame: frameRect
               pixelFormat: [[self class] defaultPixelFormat]];
  
}



- (id) initWithFrame: (NSRect)frameRect 
         pixelFormat: (NSOpenGLPixelFormat*)format
{
  self = [[self initWIthFrame: frameRect];
  if (!self)
    return nil;

  CAData *currCAData = self->_coreAnimationData;
  ASSIGN(currCAData->_pixel_format, format);

  [[NSNotificationCenter defaultCenter] 
    addObserver: self
    selector: @selector(_frameChanged:)
    name: NSViewGlobalFrameDidChangeNotification
    object: self];

  [self setPostsFrameChangedNotifications: YES];
  [[NSNotificationCenter defaultCenter] 
    addObserver: self
    selector: @selector(_frameChanged:)
    name: NSViewFrameDidChangeNotification
    object: self];

  return self;
}


- (void) dealloc
{
    CAData *currCAData = self->_coreAnimationData;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self clearGLContext];
    RELEASE(currCAData->_pixel_format);
    NSDebugMLLog(@"GL", @"deallocating");
    [super dealloc];
}

- (NSOpenGLPixelFormat*) pixelFormat
{
    CAData *currCAData = self->_coreAnimationData;
    return currCAData->_pixel_format;
}

- (void) setPixelFormat: (NSOpenGLPixelFormat*)pixelFormat
{
    CAData *currCAData = self->_coreAnimationData;
    ASSIGN(currCAData->_pixel_format, pixelFormat);
}

- (void) reshape
{
}

- (void) update
{
    NSOpenGLContext *context;
    context = [self openGLContext];
    if ([context view] == self)
      {
        [context update];
      }
}

- (BOOL) isOpaque
{
    return YES;
}

- (void) _frameChanged: (NSNotification *) aNot
{
    CAData *currCAData = self->_coreAnimationData;
    if (currCAData->_prepared)
    {
      [[self openGLContext] makeCurrentContext];
      [self update];
      [self reshape];
    }
}

-(void) _viewWillMoveToWindow: (NSWindow *) newWindow
{
    [super _viewWillMoveToWindow: newWindow];

    if ([self window] != newWindow)
      {
        // the context will be recreated in the new window if needed
        [[self openGLContext] clearDrawable];
      }
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [super initWithCoder: aDecoder];
  if (!self)
    return nil;

  if ([aDecoder allowsKeyedCoding])
    {
      [self setPixelFormat: [aDecoder decodeObjectForKey: @"NSPixelFormat"]];
    }
  else
    {
      [self setPixelFormat: [[self class] defaultPixelFormat]];
    }
 
  [[NSNotificationCenter defaultCenter] 
    addObserver: self
    selector: @selector(_frameChanged:)
    name: NSViewGlobalFrameDidChangeNotification
    object: self];

  [self setPostsFrameChangedNotifications: YES];
  [[NSNotificationCenter defaultCenter] 
    addObserver: self
    selector: @selector(_frameChanged:)
    name: NSViewFrameDidChangeNotification
    object: self];

  return self;
}

@end
