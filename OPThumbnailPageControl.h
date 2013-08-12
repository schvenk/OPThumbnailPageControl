//
//  OPThumbnailPageControl.h
//
//  Created by David Feldman on 8/6/12.
//  Copyright (c) 2012 Operation Project. Licensed under the MIT License.
//

/**
 * OPThumbnailPageControl draws a row of OPCircleImageViews in place of a standard UIPageControl.
 * It is not a UIPageControl subclass but implements much of UIPageControl's interface.
 *
 * Insert items using insertImage:atIndex: 
 *
 * Note that numberOfPages is read-only here. You can't set it directly.
 * You can, however, use currentPage as expected.
 *
 * This class can also tack an activity indicator onto its right side, to be used on Uncloaked's
 * find meeting screen.
 *
 */

#import <UIKit/UIKit.h>

@class OPThumbnailPageControl;

@protocol OPThumbnailPageControlDelegate <NSObject>
@optional
- (BOOL)thumbnailPageControl:(OPThumbnailPageControl *)thumbnailPageControl shouldSelectItemAtIndex:(int)index;
@end


@interface OPThumbnailPageControl : UIControl

@property (nonatomic, strong) id<OPThumbnailPageControlDelegate>delegate;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic, readonly) NSInteger numberOfPages;

/*!
 * Set to YES to display an activity indicator (spinner) on the right side of the view.
 */
@property (nonatomic) BOOL hasActivityIndicator;

/*!
 * Default size (diameter) of dots.
 */
@property (nonatomic) float dotSize;


/*!
 * Dots drop in size when they start to run out of room. This is the minimum diameter
 * before it goes to multiple rows.
 */
@property (nonatomic) float minimumDotSize;


/*!
 * The spacing between items. Default is 14.
 */
@property (nonatomic) float gapSize;

/*!
 * Optional properties to customize appearance of overflow text
 */
@property (nonatomic, strong) UIColor *overflowTextColor;
@property (nonatomic, strong) UIFont *overflowTextFont;

/*!
 * Insert an image (page) at the specified index.
 */
- (void)insertImage:(UIImage *)image atIndex:(NSUInteger)index;

/*!
 * Adds an image (page) after all the existing ones.
 */
- (void)addImage:(UIImage *)image;

/*!
 * Removes all images. Leaves the activity indicator alone.
 */
- (void)removeAllImages;

@end



