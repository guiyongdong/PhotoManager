//
//  GGAssetModel.m
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/5.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import "GGAssetModel.h"

@implementation GGAssetModel

+ (instancetype)modelWithAsset:(id)asset type:(GGAssetModelMediaType)mediaType {
    GGAssetModel *model = [[GGAssetModel alloc] init];
    model.mediaType = mediaType;
    model.asset = asset;
    return model;
}
+ (instancetype)modelWithAsset:(id)asset type:(GGAssetModelMediaType)mediaType timeLength:(NSString *)timeLength {
    GGAssetModel *model = [[GGAssetModel alloc] init];
    model.mediaType = mediaType;
    model.asset = asset;
    model.timeLength = timeLength;
    return model;
}

@end


@implementation GGAlbumModel



@end
