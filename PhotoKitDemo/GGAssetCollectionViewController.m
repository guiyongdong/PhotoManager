//
//  GGAssetCollectionViewController.m
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/6.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import "GGAssetCollectionViewController.h"
#import "GGPhotoManager.h"
#import "GGAssetCollectionViewCell.h"
#import "GGImageViewController.h"

@interface GGAssetCollectionViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) NSArray *assetArray;
@end

@implementation GGAssetCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerNib:[UINib nibWithNibName:@"GGAssetCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"GGAssetCollectionViewCellId"];
    // Do any additional setup after loading the view from its nib.
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    __weak typeof (self)weakSelf = self;
    [[GGPhotoManager shareManager] getAssetsFromFetchAlbumModel:self.albumModel allowPickingVideo:NO allowPickingImage:YES completion:^(NSArray<GGAssetModel *> *models) {
        weakSelf.assetArray = models;
        [weakSelf.collectionView reloadData];
    }];
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GGAssetCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GGAssetCollectionViewCellId" forIndexPath:indexPath];
    
    
    __weak typeof (cell)weakCell = cell;
    GGAssetModel *assetModel = self.assetArray[indexPath.item];
    [[GGPhotoManager shareManager] getPhotoWithAssetModel:assetModel photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (!isDegraded) {
            weakCell.iconView.image = photo;
        }
    }];
    
    
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    GGAssetModel *assetModel = self.assetArray[indexPath.item];
    GGImageViewController *imageVC = [[GGImageViewController alloc] init];
    imageVC.assetModel = assetModel;
    [self.navigationController pushViewController:imageVC animated:YES];
}


@end
