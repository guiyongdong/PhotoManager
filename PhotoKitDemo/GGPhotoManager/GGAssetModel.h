//
//  GGAssetModel.h
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/5.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/**
 *  资源的类型
 */
typedef NS_ENUM(NSInteger, GGAssetModelMediaType) {
    GGAssetModelMediaTypePhoto = 0,
    GGAssetModelMediaTypeLivePhoto,
    GGAssetModelMediaTypeVideo,
    GGAssetModelMediaTypeAudio
};



@interface GGAssetModel : NSObject

@property (nonatomic, strong) id asset; // PHAsset  或者  ALAsset  资源
@property (nonatomic, assign) GGAssetModelMediaType mediaType;
@property (nonatomic, copy) NSString *timeLength;


/// 用一个PHAsset/ALAsset实例，初始化一个照片模型
+ (instancetype)modelWithAsset:(id)asset type:(GGAssetModelMediaType)mediaType;
+ (instancetype)modelWithAsset:(id)asset type:(GGAssetModelMediaType)mediaType timeLength:(NSString *)timeLength;

@end



@interface GGAlbumModel : NSObject

@property (nonatomic, strong) NSString *name;        ///相册的名字
@property (nonatomic, assign) NSInteger count;       ///资源的数量
@property (nonatomic, strong) UIImage *coverImage; //封面图片
@property (nonatomic, strong) id album; // PHAssetCollection  或者 ALAssetsGroup




@end

