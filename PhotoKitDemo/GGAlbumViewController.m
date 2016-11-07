//
//  GGAlbumViewController.m
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/5.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import "GGAlbumViewController.h"
#import "GGPhotoManager.h"
#import "GGAlbumTableViewCell.h"
#import "GGAssetModel.h"
#import "GGAssetCollectionViewController.h"

@interface GGAlbumViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *albumArray;

@end

@implementation GGAlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.tableView registerNib:[UINib nibWithNibName:@"GGAlbumTableViewCell" bundle:nil] forCellReuseIdentifier:@"GGAlbumTableViewCellId"];
}
- (IBAction)getAllAlbums:(id)sender {
    __weak typeof (self)weakSelf = self;
    [[GGPhotoManager shareManager] getAllAlbums:NO allowPickingImage:YES completion:^(NSArray<GGAlbumModel *> *models) {
        weakSelf.albumArray = [NSArray arrayWithArray:models];
        [weakSelf.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albumArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GGAlbumTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GGAlbumTableViewCellId" forIndexPath:indexPath];
    GGAlbumModel *model = self.albumArray[indexPath.row];
    cell.iconView.image = model.coverImage;
    cell.nameLabel.text = model.name;
    cell.countLabel.text = [NSString stringWithFormat:@"%ld",model.count];
    return cell;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GGAlbumModel *albumModel = self.albumArray[indexPath.row];
    GGAssetCollectionViewController *assetVC = [[GGAssetCollectionViewController alloc] init];
    assetVC.albumModel = albumModel;
    [self.navigationController pushViewController:assetVC animated:YES];
}



@end
