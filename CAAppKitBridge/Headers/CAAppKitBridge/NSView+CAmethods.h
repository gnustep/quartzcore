/* NSView+CAmethods.h

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

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import <GNUstepBase/GSVersionMacros.h>

@interface  NSView (NSViewCAmethods)
@property BOOL wantsLayer;
- (CALayer *) makeBackingLayer;

/* GNUstep specific methods */
- (BOOL) addCARenderer: (CARenderer*) CARenderer;
- (BOOL) removeCARenderer;

/* methods from libs-gui/Headers/AppKit/NSOpenGlView.h */
+ (NSOpenGLPixelFormat*) defaultPixelFormat;
- (void) clearGLContext;
- (void) setOpenGLContext: (NSOpenGLContext*)context;
- (NSOpenGLContext*) openGLContext;
- (id) initWithFrame: (NSRect)frameRect 
         pixelFormat: (NSOpenGLPixelFormat*)format;
- (NSOpenGLPixelFormat*) pixelFormat;
- (void) setPixelFormat: (NSOpenGLPixelFormat*)pixelFormat;
- (void) reshape;
- (void) update;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
- (void) prepareOpenGL;
#endif
@end
