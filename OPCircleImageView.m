//
//  OPCircleImageView.m
//
//  Created by David Feldman on 8/3/12.
//  Copyright (c) 2012 Operation Project. Licensed under the MIT License.
//

#import "OPCircleImageView.h"
#import <QuartzCore/QuartzCore.h>

#define OPCircleImageGradientLightColor  (id)[UIColor colorWithWhite:1 alpha:0.15].CGColor
#define OPCircleImageGradientDarkColor   (id)[UIColor colorWithWhite:0 alpha:0.15].CGColor
#define OPCircleImageSelectedBorderWidth 2

@interface OPCircleImageView ()
{
    NSArray *gradientColors;
}
- (void)setup;
@end

@implementation OPCircleImageView
@synthesize image = _image;
@synthesize borderColor = _borderColor;
@synthesize bevelDirection = _bevelDirection;




#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) [self setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) [self setup];
    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.borderColor = [UIColor whiteColor];
    self.bevelDirection = OPBevelDirectionOut;
    self.borderWidth = 1;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 1;
    self.layer.shadowOpacity = 0.3;
}



#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    
    // Draw the border first as a background
    CGContextSetFillColorWithColor(ctxt, self.borderColor.CGColor);
    CGContextFillEllipseInRect(ctxt, self.bounds);
    
    // Clip the graphics context
    CGPathRef path = CGPathCreateWithEllipseInRect(CGRectInset(self.bounds, self.borderWidth, self.borderWidth), NULL);
    CGContextAddPath(ctxt, path);
    CGContextClip(ctxt);
    
    if (self.image) {
        // Draw the image, preserving aspect ratio and making a naive guess as to where the head is
        float imageAspect = self.image.size.width / self.image.size.height;
        float selfAspect = self.bounds.size.width / self.bounds.size.height;
        float scale = 1;
        if (imageAspect > selfAspect) {
            // Image's aspect ratio is "wider" than the image's, so we need to ensure the height fills.
            scale = (self.bounds.size.height + 4) / self.image.size.height;
        } else {
            scale = (self.bounds.size.width + 4) / self.image.size.width;
        }
        
        float scaledWidth = self.image.size.width * scale;
        float scaledHeight = self.image.size.height * scale;
        float scaledX = self.bounds.size.width/2 - scaledWidth/2;
        float scaledY = self.bounds.size.height/2 - scaledHeight/2;
        [self.image drawInRect:CGRectMake(scaledX, scaledY, scaledWidth, scaledHeight)];
    } else {
        // No image specified. Just draw a background color
        CGContextSetFillColorWithColor(ctxt, [UIColor grayColor].CGColor);
        CGContextFillRect(ctxt, CGRectInset(self.bounds, -4, -4));
    }
    
    // Overlay with a subtle gradient
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef)gradientColors, NULL);
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(0, self.bounds.size.height);
    CGContextDrawLinearGradient(ctxt, gradient, startPoint, endPoint, 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    CGPathRelease(path);
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}




#pragma mark - Properties

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    [self setNeedsDisplay];
}

- (void)setBevelDirection:(int)bevelDirection
{
    if (bevelDirection == OPBevelDirectionOut) {
        gradientColors = [NSArray arrayWithObjects:OPCircleImageGradientLightColor, OPCircleImageGradientDarkColor, nil];
    } else {
        gradientColors = [NSArray arrayWithObjects:OPCircleImageGradientDarkColor, OPCircleImageGradientLightColor, nil];
    }
    _bevelDirection = bevelDirection;
    [self setNeedsDisplay];
}

- (void)setBorderWidth:(float)borderWidth
{
    _borderWidth = borderWidth;
    [self setNeedsDisplay];
}

@end
