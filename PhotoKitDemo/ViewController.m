//
//  ViewController.m
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/2.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import "ViewController.h"
#import "GGPhotoManager.h"
#import "GGAlbumViewController.h"



@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UITextField *input;
@property (weak, nonatomic) IBOutlet UIImageView *imageView3;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)getAllAblums:(id)sender {
    GGAlbumViewController *albumVC = [[GGAlbumViewController alloc] init];
    [self.navigationController pushViewController:albumVC animated:YES];
}

- (IBAction)getCameraRollAlbum:(id)sender {
    __weak typeof (self)weakSelf = self;;
    [[GGPhotoManager shareManager] getCameraRollAlbum:NO allowPickingImage:YES completion:^(GGAlbumModel *model) {
        weakSelf.imageView.image = model.coverImage;
        weakSelf.numberLabel.text = [NSString stringWithFormat:@"%@相册的资源数量为：%ld",model.name,model.count];
    }];
}
- (IBAction)addImageToGroup:(id)sender {
    UIImage *image = [UIImage imageNamed:@"bbb"];
    __weak typeof (self)weakSelf = self;
    [[GGPhotoManager shareManager] savePhotoWithImage:image groupName:self.input.text completion:^(BOOL isSuccess) {
        if (isSuccess) {
            weakSelf.imageView3.image = image;
        }
    }];
}

- (IBAction)addImage:(id)sender {
    UIImage *image = [UIImage imageNamed:@"bbb"];
    __weak typeof (self)weakSelf = self;
    [[GGPhotoManager shareManager] savePhotoToCameraRollWithImage:image completion:^(BOOL isSuccess) {
        if (isSuccess) {
            weakSelf.imageView2.image = image;
        }
    }];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}



@end
