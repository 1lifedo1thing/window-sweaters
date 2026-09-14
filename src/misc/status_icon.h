#pragma once
#import <Cocoa/Cocoa.h>

// Original vector mark; kept in sync with assets/yarn-menu-icon.svg.
// The broad winding strands and needle heads are tuned for an 18 pt template.
static NSImage* knit_status_icon(void) {
  NSImage* image = [NSImage imageWithSize:NSMakeSize(18, 18) flipped:NO
    drawingHandler:^BOOL(NSRect rect) {
      (void)rect;
      [NSColor.blackColor setStroke];
      [NSColor.blackColor setFill];
      NSBezierPath* needles = [NSBezierPath bezierPath];
      needles.lineWidth = 1.35;
      needles.lineCapStyle = NSLineCapStyleRound;
      [needles moveToPoint:NSMakePoint(3.2, 15.8)];
      [needles lineToPoint:NSMakePoint(5.7, 12.65)];
      [needles moveToPoint:NSMakePoint(14.8, 15.8)];
      [needles lineToPoint:NSMakePoint(12.3, 12.65)];
      [needles stroke];
      [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(1.8, 14.4, 2.8, 2.8)] fill];
      [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(13.4, 14.4, 2.8, 2.8)] fill];

      NSBezierPath* ball = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(2.8, 1.2, 12.4, 12.4)];
      [NSGraphicsContext saveGraphicsState];
      [ball addClip];
      NSBezierPath* strands = [NSBezierPath bezierPath];
      strands.lineWidth = 1.3;
      strands.lineCapStyle = NSLineCapStyleRound;
      [strands moveToPoint:NSMakePoint(5.5, 13.4)];
      [strands curveToPoint:NSMakePoint(5.5, 1.4)
             controlPoint1:NSMakePoint(11, 10.4) controlPoint2:NSMakePoint(11, 4.4)];
      [strands moveToPoint:NSMakePoint(9.5, 13.8)];
      [strands curveToPoint:NSMakePoint(9.5, 1)
             controlPoint1:NSMakePoint(14.3, 10.3) controlPoint2:NSMakePoint(14.3, 4.5)];
      [strands moveToPoint:NSMakePoint(2.2, 6.7)];
      [strands curveToPoint:NSMakePoint(9.1, 9.7)
             controlPoint1:NSMakePoint(4.4, 8.8) controlPoint2:NSMakePoint(6.9, 9.6)];
      [strands moveToPoint:NSMakePoint(3.5, 3.2)];
      [strands curveToPoint:NSMakePoint(9.2, 5.3)
             controlPoint1:NSMakePoint(5.1, 4.7) controlPoint2:NSMakePoint(7, 5.4)];
      [strands stroke];
      [NSGraphicsContext restoreGraphicsState];
      ball.lineWidth = 1.5;
      [ball stroke];
      return YES;
    }];
  image.template = YES;
  image.accessibilityDescription = @"Window Sweaters";
  return image;
}
