//
//  OPViewController.m
//  OPThumbnailPageControlTest
//
//  Created by Dave Feldman on 8/12/13.
//  Copyright (c) 2013 Operation Project. All rights reserved.
//

#import "OPViewController.h"
#import "OPThumbnailPageControl.h"
#import "OPCircleImageView.h"

@interface OPViewController ()
@property (weak, nonatomic) IBOutlet OPCircleImageView *circleImageView;
@property (weak, nonatomic) IBOutlet OPThumbnailPageControl *thumbnailPageControl;
@end

@implementation OPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.circleImageView.image = [UIImage imageNamed:@"monkey"];

    [self.thumbnailPageControl addImage:[UIImage imageNamed:@"monkey"]];
    self.thumbnailPageControl.currentPage = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addPage:(id)sender {
    [self.thumbnailPageControl addImage:[UIImage imageNamed:@"monkey"]];
}

@end
