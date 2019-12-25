/* Demo/DemoController.m

   Copyright (C) 2018 Free Software Foundation, Inc.

   Author: Stjepan Brkic <stjepanbrkicc@gmail.com>
   Date: July 2018

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

#import "DemoController.h"

@interface DebugButtonCell : NSButtonCell

@end

@implementation DebugButtonCell
- (void) _drawBorderAndBackgroundWithFrame: (NSRect)cellFrame
                                    inView: (NSView*)controlView
{
  NSLog(@"kmu");
  [super _drawBorderAndBackgroundWithFrame: cellFrame inView: controlView];
}
@end


@interface DebugButton : NSButton
@end


@implementation DebugButton
+ initialize
{
  [super initialize];
  [self setCellClass: [DebugButtonCell class]];
}
- (void) drawRect: (NSRect)aRect
{
  [super drawRect: aRect];
  NSLog(@"DebugButton: drawRect");
}
@end

@implementation DemoController

@synthesize window=_window;
@synthesize mainView=_mainView;
@synthesize renderer=_renderer;

- (void) applicationDidFinishLaunching: (id)t
{
  /* Test the drawing into the context */
  self->_window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,800,600)
                                        styleMask: NSTitledWindowMask | NSClosableWindowMask
                                          backing: NSBackingStoreBuffered
                                            defer: NO];
  self->_mainView = [[DebugButton alloc] initWithFrame: [[self->_window contentView] frame]];
  [self->_mainView setTitle: @"hello"];
  [self->_window setContentView: self->_mainView];
  [self->_mainView setWantsLayer: YES];
  NSLog(@"mainView wantsLayer value: %d", [self->_mainView wantsLayer]);
  [self->_window makeKeyAndOrderFront: nil];
  [[self->_mainView _gsLayer] retain];

  /*
  CGColorRef yellowColor = CGColorCreateGenericRGB(1, 1, 0, 1);
  [[self->_mainView _gsLayer] setBackgroundColor: yellowColor];
  */

  /* set up the NSTimer */
  NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 
                                                    target: self 
                                                  selector: @selector(drawRect:) 
                                                  userInfo: nil
                                                   repeats: YES];

}

-(void) drawRect: (NSTimer*)t
{
  NSLog(@"mainView is at %p", self->_mainView);
  //[[self->_mainView _gsCreateOpenGLContext] makeCurrentContext];
  NSLog(@"Context is at %p", [self->_mainView _gsCreateOpenGLContext]);
  NSLog(@"_gsLayer %p", [self->_mainView _gsLayer]);
  [[self->_mainView _gsLayer] setNeedsDisplay];

  [[self->_mainView _gsCreateOpenGLContext] makeCurrentContext];

  glClear(GL_COLOR_BUFFER_BIT);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, [self->_mainView frame].size.width, 0, [self->_mainView frame].size.height, -2500, 2500);
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  NSLog(@"renderer: %p : %@", [self->_mainView _gsRendererTemp], [self->_mainView _gsRendererTemp]);
  [[self->_mainView _gsRendererTemp] addUpdateRect: [[self->_mainView _gsRendererTemp] bounds]];
  [[self->_mainView _gsRendererTemp] beginFrameAtTime: CACurrentMediaTime()
                          timeStamp: NULL];

  [[self->_mainView _gsRendererTemp] render];
  [[self->_mainView _gsRendererTemp] endFrame];

  glFlush();
  [[self->_mainView _gsCreateOpenGLContext] flushBuffer];

}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed: (id)sender
{
  return YES;
}

-(void)dealloc
{
  [super dealloc];
}

@end
