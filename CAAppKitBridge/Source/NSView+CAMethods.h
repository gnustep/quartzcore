/* NSView+CAMethods.h

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

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface  NSView (CAmethods)
@property BOOL wantsLayer;
- (CALayer *) makeBackingLayer;
- (void)drawLayer: (CALayer *)layer 
        inContext: (CGContextRef)ctx;

/* GNUstep specific methods */
- (CALayer*) _gsLayer;
- (BOOL) _gsAddCARenderer: (CARenderer*)renderer;
- (BOOL) _gsRemoveCARenderer;
- (CARenderer*) _gsRendererTemp;
- (NSOpenGLContext*) _gsCreateOpenGLContext;
- (NSOpenGLContext*) _gsGetOpenGLContext;

@end
