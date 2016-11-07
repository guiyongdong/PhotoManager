//
//  GGImageViewController.m
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/6.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import "GGImageViewController.h"
#import "GGPhotoManager.h"

@interface GGImageViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation GGImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    __weak typeof (self)weakSelf = self;
    [[GGPhotoManager shareManager] getOriginalPhotoWithAssetModel:self.assetModel completion:^(UIImage *photo, NSDictionary *info) {
        weakSelf.imageView.image = photo;
    }];
}


@end
