//
//  OPCircleImageView.h
//
//  Created by David Feldman on 8/3/12.
//  Copyright (c) 2012 Operation Project. Licensed under the MIT License.
//

/**
 * OPCircleImageView draws an image onscreen, scaled and clipped to an ellipse defined by the view's
 * bounds. It draws a border, a subtle drop shadow, and a slight gradient to create a beveled effect.
 *
 * OPCircleImageView is NOT a subclass of UIImageView: UIImageView isn't designed to be subclassed.
 * It does behave a bit like UIImageView.
 */

#define OPBevelDirectionIn 0
#define OPBevelDirectionOut 1

#import <UIKit/UIKit.h>

@interface OPCircleImageView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic) float borderWidth;

/*!
 * Whether the slight bevel effect is an outie or an innie. Accepted values are
 * OPBevelDirectionIn and OPBevelDirectionOut. Default is out.
 */
@property (nonatomic) int bevelDirection;
@end
