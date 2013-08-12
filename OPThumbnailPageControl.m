//
//  OPThumbnailPageControl.m
//
//  Created by David Feldman on 8/6/12.
//  Copyright (c) 2012 Operation Project. Licensed under the MIT License.
//

#import "OPThumbnailPageControl.h"
#import "OPCircleImageView.h"

#define DefaultDotSize 32
#define DefaultMinimumDotSize 26
#define DefaultGapSize 8
#define DefaultMaxRows 3
#define DefaultOverflowTextColor [UIColor whiteColor]
#define DefaultOverflowTextFont [UIFont boldSystemFontOfSize:13]
#define AnimationDuration 0.33
#define PreAnimationDotScale 0.1
#define PreAnimationDotAlpha 0.25
#define PreAnimationDotOffset 3
#define StandardActivityIndicatorHeight 20
#define OverflowLabelStringFormat @"Page %d of %d"

#define DotBorderColor [UIColor whiteColor]
#define DotSelectedBorderColor [UIColor colorWithHue:0.055 saturation:1 brightness:0.9 alpha:1]


@interface OPThumbnailPageControl () <UIGestureRecognizerDelegate>
{
    int _ucCurrentPage;
    NSMutableArray *cachedSubviewPositions; // Used to avoid recalculating twice when adding a subview
    
    UILabel *overflowLabel;
}

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, readonly) int maximumNumberOfRows;

- (void)setup;
- (void)calculateSubviewPositions;
- (void)updateSubviewPositions;
- (void)updateOverflowText;
- (void)didTapSubview:(id)sender;
@end

@implementation OPThumbnailPageControl
@synthesize hasActivityIndicator = _hasActivityIndicator;
@synthesize gapSize = _gapSize;
@synthesize activityIndicator = _activityIndicator;
@synthesize delegate = _delegate;
@synthesize dotSize = _dotSize;
@synthesize minimumDotSize = _minimumDotSize;
@synthesize numberOfPages = _numberOfPages;
@synthesize overflowTextColor = _overflowTextColor;
@synthesize overflowTextFont = _overflowTextFont;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setup];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self setup];
    return self;
}

/*!
 * Initialization code shared by all initializers.
 */
- (void)setup
{
    self.dotSize = DefaultDotSize;
    self.minimumDotSize = DefaultMinimumDotSize;
    self.gapSize = DefaultGapSize;
    self.hasActivityIndicator = NO;
    self.backgroundColor = [UIColor clearColor];
    self.overflowTextFont = DefaultOverflowTextFont;
    self.overflowTextColor = DefaultOverflowTextColor;
    _ucCurrentPage = -1;
}




#pragma mark - Drawing and Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateSubviewPositions];

    // Clear cached positions so it's recalculated next time
    cachedSubviewPositions = nil;
}

/*!
 * Calculates positions and sizes for all subviews but doesn't actually move them, so
 * they can be animated.
 */
- (void)calculateSubviewPositions
{
    cachedSubviewPositions = [NSMutableArray arrayWithCapacity:self.subviews.count];

    if (overflowLabel) {
        [overflowLabel sizeToFit];
        float totalWidth = overflowLabel.frame.size.width;
        if (self.hasActivityIndicator) totalWidth += StandardActivityIndicatorHeight;
        float x = round(self.bounds.size.width/2 - totalWidth/2);
        
        [cachedSubviewPositions addObject:[NSValue valueWithCGRect:CGRectMake(x,
                                                                              round(self.bounds.size.height/2 - overflowLabel.frame.size.height/2),
                                                                              overflowLabel.frame.size.width,
                                                                              overflowLabel.frame.size.height)]];
        if (self.hasActivityIndicator) {
            [cachedSubviewPositions addObject:
             [NSValue valueWithCGRect:CGRectMake(x + overflowLabel.frame.size.width + self.gapSize,
                                                 self.bounds.size.height/2 - StandardActivityIndicatorHeight/2,
                                                 StandardActivityIndicatorHeight,
                                                 StandardActivityIndicatorHeight)]];
        }
    } else {
        // Determine actual dot size as somewhere between minimum and specified
        float actualDotSize = self.dotSize;
        int rows = 1;
        int dotsPerRow = self.subviews.count;
        float fullWidth = (self.dotSize + self.gapSize) * self.subviews.count - self.gapSize;
        if (fullWidth > self.bounds.size.width) {
            // Need to scale down the dots

            actualDotSize = (self.bounds.size.width + self.gapSize) / self.subviews.count - self.gapSize;
            if (actualDotSize < self.minimumDotSize) {
                // Minimum dot size still doesn't fit all the dots. We need multiple rows.
                
                actualDotSize = self.minimumDotSize;
                dotsPerRow = (self.bounds.size.width + self.gapSize) / (self.minimumDotSize + self.gapSize);
                rows = (int)ceil(self.subviews.count / (double)dotsPerRow);
                
                if (rows > self.maximumNumberOfRows) {
                    // More dots than we can display in the max number of rows. Set up overflow state, then call
                    // this function recursively
                    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                    overflowLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                    overflowLabel.font = self.overflowTextFont;
                    overflowLabel.textColor = self.overflowTextColor;
                    overflowLabel.backgroundColor = [UIColor clearColor];
                    [self updateOverflowText];
                    [self addSubview:overflowLabel];
                    
                    if (_activityIndicator) {
                        [self addSubview:_activityIndicator];
                        _activityIndicator.transform = CGAffineTransformIdentity;
                    }
                    
                    [self calculateSubviewPositions];
                    
                    // Pre-set overflow label frame so it animates in properly
                    overflowLabel.frame = [[cachedSubviewPositions objectAtIndex:0] CGRectValue];
                    overflowLabel.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(PreAnimationDotScale, PreAnimationDotScale), 0, self.dotSize*PreAnimationDotOffset);
                    overflowLabel.alpha = PreAnimationDotAlpha;

                    
                    return;
                }
            }
        }
        actualDotSize = roundf(actualDotSize);
        
        // Initial coordinates should allow views to be centered
        float xStart = self.bounds.size.width/2 - actualDotSize*dotsPerRow/2 - self.gapSize*(dotsPerRow-1)/2;
        float contentHeight = rows * (actualDotSize + self.gapSize) - self.gapSize;
        float yStart = self.bounds.size.height/2 - contentHeight/2;
        
        for (int i=0;i<self.subviews.count;i++) {
            int currentRow = i / dotsPerRow;
            int positionInRow = i - (currentRow * dotsPerRow);
            float x = xStart + positionInRow*(actualDotSize + self.gapSize);
            float y = yStart + currentRow * (actualDotSize + self.gapSize);
            CGRect frame = CGRectMake(roundf(x), roundf(y), actualDotSize, actualDotSize);
            [cachedSubviewPositions addObject:[NSValue valueWithCGRect:frame]];
        }
        
        if (self.hasActivityIndicator) {
            float activityIndicatorScale = actualDotSize / StandardActivityIndicatorHeight;
            self.activityIndicator.transform = CGAffineTransformMakeScale(activityIndicatorScale, activityIndicatorScale);
        }
    }
}

/*!
 * Repositions the subviews, recalculating their positions only if there isn't a cached
 * array of positions already. Clears that array when done.
 */
- (void)updateSubviewPositions
{
    if (!cachedSubviewPositions) [self calculateSubviewPositions];
    
    for (int i=0;i<cachedSubviewPositions.count;i++) {
        UIView *subview = [self.subviews objectAtIndex:i];
        subview.frame = [[cachedSubviewPositions objectAtIndex:i] CGRectValue];
    }
    
    if (overflowLabel) {
        overflowLabel.transform = CGAffineTransformIdentity;
        overflowLabel.alpha = 1;
    }
}




#pragma mark - Item Management

/*!
 * Inserts an image (page) into the control at the specified index.
 * Modeled after the equivalent NSMutableArray method.
 */
- (void)insertImage:(UIImage *)image atIndex:(NSUInteger)index
{
    OPCircleImageView *imageView;
    
    _numberOfPages++;

    // Need to shift the current page property without actually switching the appearance,
    // so use the member variable rather than the property.
    if ((_ucCurrentPage != -1) && (index <= _ucCurrentPage)) {
        _ucCurrentPage++;
    }
    
    if (overflowLabel) {
        [self updateOverflowText];
    } else {
        imageView = [[OPCircleImageView alloc] initWithFrame:CGRectMake(0,0,10,10)];
        imageView.image = image;
        imageView.borderColor = DotBorderColor;
        imageView.userInteractionEnabled = YES;
        [self insertSubview:imageView atIndex:index];

        // Set the new view's frame here so it animates into place properly
        [self calculateSubviewPositions];
        if (!overflowLabel) {
            imageView.frame = [[cachedSubviewPositions objectAtIndex:index] CGRectValue];
            
            // Make the new view tiny, transparent, and shift down so it animates nicely
            imageView.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(PreAnimationDotScale, PreAnimationDotScale), 0, self.dotSize*PreAnimationDotOffset);
            imageView.alpha = PreAnimationDotAlpha;
            
            // Set up support for interaction -- @todo how is this from a performance perspective
            UITapGestureRecognizer *rec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapSubview:)];
            rec.delegate = self;
            [imageView addGestureRecognizer:rec];
        }
    }

    [UIView transitionWithView:self duration:AnimationDuration options:UIViewAnimationCurveEaseInOut animations:^{
        if (!overflowLabel) {
            imageView.transform = CGAffineTransformIdentity;
            imageView.alpha = 1;
        }
        [self updateSubviewPositions];
    } completion:nil];
}

/*!
 * Adds an image at the end of the control (but leaves the activity indicator at the
 * end, when present). Modeled after the equivalent NSMutableArray method.
 */
- (void)addImage:(UIImage *)image
{
    [self insertImage:image atIndex:self.numberOfPages];
}

- (void)removeAllImages
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (_activityIndicator)
        [self addSubview:_activityIndicator];
    _numberOfPages = 0;
    overflowLabel = nil;
}

- (void)updateOverflowText
{
    overflowLabel.text = [NSString stringWithFormat:OverflowLabelStringFormat, self.currentPage+1, self.numberOfPages];
    [self setNeedsLayout];
}



#pragma mark - Gesture recognizer

- (void)didTapSubview:(UITapGestureRecognizer *)rec
{
    if (self.delegate) {
        for (int i=0;i<self.numberOfPages;i++) {
            if ([self.subviews objectAtIndex:i] == rec.view) {
                if ([self.delegate respondsToSelector:@selector(thumbnailPageControl:shouldSelectItemAtIndex:)] &&
                    [self.delegate thumbnailPageControl:self shouldSelectItemAtIndex:i]) {
                    self.currentPage = i;
                }
                NSLog(@"tapped %d", i);
                break;
            }
        }
    }
}


#pragma mark - Properties

- (void)setHasActivityIndicator:(BOOL)hasActivityIndicator
{
    if (hasActivityIndicator && !_hasActivityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        [_activityIndicator startAnimating];
        [self addSubview:_activityIndicator];
        [self setNeedsLayout];
    } else if (!hasActivityIndicator) {
        [_activityIndicator removeFromSuperview];
        _activityIndicator = nil;
        if (_hasActivityIndicator) [self setNeedsLayout];
    }
    _hasActivityIndicator = hasActivityIndicator;
}

- (void)setOverflowTextFont:(UIFont *)overflowTextFont
{
    _overflowTextFont = overflowTextFont;
    if (overflowLabel) {
        overflowLabel.font = overflowTextFont;
        [self setNeedsLayout];
    }
}

- (void)setOverflowTextColor:(UIColor *)overflowTextColor
{
    _overflowTextColor = overflowTextColor;
    overflowLabel.textColor = overflowTextColor;
}

- (int)maximumNumberOfRows
{
    return (self.frame.size.height + self.gapSize) / (self.minimumDotSize + self.gapSize);
}




#pragma mark - Superclass property overrides

- (NSInteger)currentPage
{
    return _ucCurrentPage;
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    int oldCurrentPage = _ucCurrentPage;
    _ucCurrentPage = currentPage;
    
    if (self.numberOfPages) {
        if (overflowLabel) {
            [self updateOverflowText];
        } else {
            if (_ucCurrentPage > self.numberOfPages-1)
                _ucCurrentPage = 0;
            
            OPCircleImageView *oldCurrent = (oldCurrentPage == -1) ? nil : [self.subviews objectAtIndex:oldCurrentPage];
            OPCircleImageView *newCurrent = [self.subviews objectAtIndex:_ucCurrentPage];
            
            if (oldCurrent != newCurrent) {
                oldCurrent.borderColor = DotBorderColor;
                oldCurrent.bevelDirection = OPBevelDirectionOut;
                oldCurrent.borderWidth = 1;
                newCurrent.borderColor = DotSelectedBorderColor;
                newCurrent.bevelDirection = OPBevelDirectionIn;
                newCurrent.borderWidth = 2;
            }
        }
    } else {
        _ucCurrentPage = -1;
    }
    
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

@end
