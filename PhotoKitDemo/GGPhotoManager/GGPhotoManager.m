//
//  GGImageManager.m
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/5.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import "GGPhotoManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "GGAssetModel.h"

#define iOS7Later ([UIDevice currentDevice].systemVersion.floatValue >= 7.0f)
#define iOS8Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f)
#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)
#define iOS9_1Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)
#define GGWindowWidth [UIScreen mainScreen].bounds.size.width
static CGFloat GGScreenScale;


@interface GGPhotoManager ()

@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;

@property (nonatomic, assign) NSInteger albumLoadOverCount;

@end

@implementation GGPhotoManager


+ (instancetype)shareManager {
    static GGPhotoManager *imageManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageManager = [[GGPhotoManager alloc] init];
        imageManager.cachingImageManager = [[PHCachingImageManager alloc] init];
        imageManager.cachingImageManager.allowsCachingHighQualityImages = YES;
        imageManager.albumLoadOverCount = 0;
        //默认按照创建时间排序
        imageManager.sortAscendingByModificationDate = YES;
        imageManager.photoPreviewMaxWidth = 600;
        GGScreenScale = 2.0;
        if (GGWindowWidth > 700) {
            GGScreenScale = 1.5;
        }
    });
    return imageManager;
}
- (ALAssetsLibrary *)assetLibrary {
    if (_assetLibrary == nil) {
        _assetLibrary = [[ALAssetsLibrary alloc] init];
    }
    return _assetLibrary;
}


/**
 *  返回YES如果得到了授权
 */
- (BOOL)authorizationStatusAuthorized {
    if (iOS8Later) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) return YES;
    } else {
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark - 获取相机相册/所有的相册数组

- (void)getCameraRollAlbum:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(GGAlbumModel *model))completion {
    __block GGAlbumModel *albumModel;
    __weak typeof (self)weakSelf = self;
    //iOS8 之前用 ALAssetsLibrary  iOS8之后用 PhotoKit
    if (iOS8Later) {
        //根据筛选条件筛选
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        //不允许视频
        if (!allowPickingVideo) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeImage];
        }
        //不允许照片
        if (!allowPickingImage) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
        }
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
        PHFetchResult *smartResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        for (PHAssetCollection *collection in smartResult) {
            NSString *name = collection.localizedTitle;
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"] || [name isEqualToString:@"所有照片"] || [name isEqualToString:@"All Photos"]) {
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                albumModel = [weakSelf modelWithResult:fetchResult name:name album:collection];
                [weakSelf getCoverImageWithAlbumModel:albumModel completion:^(UIImage *coverImage) {
                    albumModel.coverImage = coverImage;
                    if (completion) {
                        completion(albumModel);
                    }
                }];
            }
        }
    }else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([group numberOfAssets] < 1) {
                return ;
            }
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"] || [name isEqualToString:@"所有照片"] || [name isEqualToString:@"All Photos"]) {
                albumModel = [weakSelf modelWithResult:group name:name album:group];
                //获取封面
                [weakSelf getCoverImageWithAlbumModel:albumModel completion:^(UIImage *coverImage) {
                    albumModel.coverImage = coverImage;
                    if (completion) {
                        completion(albumModel);
                    }
                    *stop = YES;
                }];
            }
        } failureBlock:^(NSError *error) {
            if (completion) {
                completion(nil);
            }
        }];
    }
}
- (void)getAllAlbums:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<GGAlbumModel *> *models))completion {
    __block NSMutableArray *albumArr = [NSMutableArray array];
    __weak typeof (self)weakSelf = self;
    if (iOS8Later) {
        //根据筛选条件筛选
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        //不允许视频
        if (!allowPickingVideo) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeImage];
        }
        //不允许照片
        if (!allowPickingImage) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
        }
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
        PHAssetCollectionSubtype smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumVideos;
        if (iOS9Later) {
            smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumScreenshots | PHAssetCollectionSubtypeSmartAlbumSelfPortraits | PHAssetCollectionSubtypeSmartAlbumVideos;
        }
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:smartAlbumSubtype options:nil];
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular | PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        GGAlbumModel *albumModel;
        for (PHAssetCollection *collection in smartAlbums) {
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (result.count < 1) {
                continue;
            }
            
            NSString *name = collection.localizedTitle;
            if ([self hasSubString:name subStr:@"Deleted"] || [self hasSubString:name subStr:@"最近删除"]) {
                continue;
            }
            albumModel = [weakSelf modelWithResult:result name:name album:collection];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"] || [name isEqualToString:@"所有照片"] || [name isEqualToString:@"All Photos"]) {
                [albumArr insertObject:albumModel atIndex:0];
            } else {
                [albumArr addObject:albumModel];
            }
            self.albumLoadOverCount++;
        }
        
        for (PHAssetCollection *collection in albums) {
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (result.count < 1) {
                continue;
            }
            NSString *name = collection.localizedTitle;
            albumModel = [weakSelf modelWithResult:result name:name album:collection];
            if ([collection.localizedTitle isEqualToString:@"My Photo Stream"] || [collection.localizedTitle isEqualToString:@"我的照片流"] ) {
                if (albumArr.count) {
                    [albumArr insertObject:albumModel atIndex:1];
                }else {
                    [albumArr addObject:albumModel];
                }
            } else {
                [albumArr addObject:albumModel];
            }
            self.albumLoadOverCount++;
        }
        
        for (GGAlbumModel* albumModel in albumArr) {
            [self getCoverImageWithAlbumModel:albumModel completion:^(UIImage *coverImage) {
                weakSelf.albumLoadOverCount--;
                albumModel.coverImage = coverImage;
                [weakSelf callBackAllAlbums:albumArr Completion:completion];
            }];
        }
    }else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                if (completion && albumArr.count > 0) completion(albumArr);
            }
            if ([group numberOfAssets] < 1) {
                return ;
            }
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"] || [name isEqualToString:@"所有照片"] || [name isEqualToString:@"All Photos"]) {
                [albumArr insertObject:[weakSelf modelWithResult:group name:name album:group] atIndex:0];
            } else if ([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我的照片流"]) {
                if (albumArr.count) {
                    [albumArr insertObject:[weakSelf modelWithResult:group name:name album:group] atIndex:1];
                } else {
                    [albumArr addObject:[weakSelf modelWithResult:group name:name album:group]];
                }
            } else {
                [albumArr addObject:[weakSelf modelWithResult:group name:name album:group]];
            }
            for (GGAlbumModel* albumModel in albumArr) {
                [self getCoverImageWithAlbumModel:albumModel completion:^(UIImage *coverImage) {
                    
                    albumModel.coverImage = coverImage;
                }];
            }
            if (completion) completion(albumArr);
            
        } failureBlock:^(NSError *error) {
            if (completion) {
                completion(nil);
            }
        }];
    }
}


#pragma mark -
#pragma mark - 获取某个相册下的资源
/**
 *  获取相册下的资源数组
 *
 *  @param albumModel        相册对象
 *  @param allowPickingVideo 是否包含视频
 *  @param allowPickingImage 是否包含图片
 *  @param completion        回调
 */
- (void)getAssetsFromFetchAlbumModel:(GGAlbumModel *)albumModel allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<GGAssetModel *> *models))completion {
    NSMutableArray *photoArr = [NSMutableArray array];
    id album = albumModel.album;
    __weak typeof (self)weakSelf = self;
    if ([album isKindOfClass:[PHAssetCollection class]]) {
        //根据筛选条件筛选
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        //不允许视频
        if (!allowPickingVideo) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeImage];
        }
        //不允许照片
        if (!allowPickingImage) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
        }
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)album options:option];
        [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PHAsset *asset = (PHAsset *)obj;
            GGAssetModelMediaType mediaType = GGAssetModelMediaTypePhoto;
            if (asset.mediaType == PHAssetMediaTypeVideo)      mediaType = GGAssetModelMediaTypeVideo;
            else if (asset.mediaType == PHAssetMediaTypeAudio) mediaType = GGAssetModelMediaTypeAudio;
            if (!allowPickingVideo && mediaType == GGAssetModelMediaTypeVideo) return;
            if (!allowPickingImage && mediaType == GGAssetModelMediaTypePhoto) return;
            
            NSString *timeLength = mediaType == GGAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
            timeLength = [weakSelf getNewTimeFromDurationSecond:timeLength.integerValue];
            [photoArr addObject:[GGAssetModel modelWithAsset:asset type:mediaType timeLength:timeLength]];
        }];
        if (completion) {
            completion(photoArr);
        }
        
    }else if ([album isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)album;
        if (allowPickingImage && allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allAssets]];
        } else if (allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        } else if (allowPickingImage) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        ALAssetsGroupEnumerationResultsBlock resultBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop)  {
            if (result == nil) {
                if (completion) completion(photoArr);
            }
            GGAssetModelMediaType mediaType = GGAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                [photoArr addObject:[GGAssetModel modelWithAsset:result type:mediaType]];
                return;
            }
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                mediaType = GGAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                timeLength = [weakSelf getNewTimeFromDurationSecond:timeLength.integerValue];
                [photoArr addObject:[GGAssetModel modelWithAsset:result type:mediaType timeLength:timeLength]];
            } else {
                [photoArr addObject:[GGAssetModel modelWithAsset:result type:mediaType]];
            }
        };
        
        if (self.sortAscendingByModificationDate) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (resultBlock) { resultBlock(result,index,stop); }
            }];
        } else {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (resultBlock) { resultBlock(result,index,stop); }
            }];
        }
    }
    
}

/**
 *  获取某个相册某个下标的资源
 *
 *  @param albumModel        相册对象
 *  @param index             下表
 *  @param allowPickingVideo 是否包含视频
 *  @param allowPickingImage 是否包含图片
 *  @param completion        回调
 */
- (void)getAssetFromFetchAlbumModel:(GGAlbumModel *)albumModel atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(GGAssetModel *model))completion {
    id album = albumModel.album;
    if ([album isKindOfClass:[PHAssetCollection class]]) {
        //根据筛选条件筛选
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        //不允许视频
        if (!allowPickingVideo) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeImage];
        }
        //不允许照片
        if (!allowPickingImage) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
        }
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)album options:option];
        PHAsset *asset;
        @try {
            asset = fetchResult[index];
        }
        @catch (NSException* e) {
            if (completion) completion(nil);
            return;
        }
        GGAssetModelMediaType mediaType = GGAssetModelMediaTypePhoto;
        if (asset.mediaType == PHAssetMediaTypeVideo)      mediaType = GGAssetModelMediaTypeVideo;
        else if (asset.mediaType == PHAssetMediaTypeAudio) mediaType = GGAssetModelMediaTypeAudio;
        NSString *timeLength = mediaType == GGAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
        timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
        GGAssetModel *assetModel = [GGAssetModel modelWithAsset:asset type:mediaType timeLength:timeLength];
        if (completion) {
            completion(assetModel);
        }
    }else if ([album isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)album;
        if (allowPickingImage && allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allAssets]];
        } else if (allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        } else if (allowPickingImage) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        @try {
            [group enumerateAssetsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (!result) {
                    if (completion) completion(nil);
                    return ;
                }
                GGAssetModel *assetModel;
                GGAssetModelMediaType mediaType = GGAssetModelMediaTypePhoto;
                if (!allowPickingVideo) {
                    assetModel = [GGAssetModel modelWithAsset:result type:mediaType];
                    if (completion) completion(assetModel);
                    return;
                }
                /// 允许视频
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                    mediaType = GGAssetModelMediaTypeVideo;
                    NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                    NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                    timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                    assetModel = [GGAssetModel modelWithAsset:result type:mediaType timeLength:timeLength];
                } else {
                    assetModel = [GGAssetModel modelWithAsset:result type:mediaType];
                }
                if (completion) completion(assetModel);
            }];
        }
        @catch (NSException* e) {
            if (completion) completion(nil);
        }
    }
}


#pragma mark -
#pragma mark - 获取照片


/**
 *  获取封面图片
 *
 *  @param model      GGAlbumModel
 *  @param completion 回调
 */
- (void)getCoverImageWithAlbumModel:(GGAlbumModel *)model completion:(void (^)(UIImage *coverImage))completion {
    
    id album = model.album;
    if ([album isKindOfClass:[PHAssetCollection class]]) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)album options:nil];
        id asset = [fetchResult lastObject];
        if (!self.sortAscendingByModificationDate) {
            asset = [fetchResult firstObject];
        }
        [self getPhotoWithAsset:asset photoWidth:100 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (!isDegraded) {
                //封面不是缩略图再返回
                if (completion) completion(photo);
            }
        }];
    }else if ([album isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)album;
        UIImage *postImage = [UIImage imageWithCGImage:group.posterImage];
        if (completion) completion(postImage);
    }
}

/**
 *  获取照片本身
 *
 *  @param asset      GGAssetModel
 *  @param completion 回调
 *
 *  @return PHImageRequestID
 */
- (PHImageRequestID)getPhotoWithAssetModel:(GGAssetModel *)assetModel completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    PHImageRequestID requestId = [self getPhotoWithAsset:assetModel.asset completion:completion];
    return requestId;
}
/**
 *  获取一定宽高的正方形图片
 *
 *  @param assetModel GGAssetModel
 *  @param photoWidth 宽
 *  @param completion 回调
 *
 *  @return PHImageRequestID
 */
- (PHImageRequestID)getPhotoWithAssetModel:(GGAssetModel *)assetModel photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    PHImageRequestID requestId = [self getPhotoWithAsset:assetModel.asset photoWidth:photoWidth completion:completion];
    return requestId;
}
/**
 *  获取原图
 *
 *  @param assetModel GGAssetModel
 *  @param completion 回调
 */
- (void)getOriginalPhotoWithAssetModel:(GGAssetModel *)assetModel completion:(void (^)(UIImage *photo,NSDictionary *info))completion {
    [self getOriginalPhotoWithAsset:assetModel.asset completion:completion];
}


/**
 *  保存照片到指定相册
 *
 *  @param image      图片
 *  @param groupName  相册名
 *  @param completion 回调
 */
- (void)savePhotoWithImage:(UIImage *)image groupName:(NSString *)groupName completion:(void (^)(BOOL isSuccess))completion {
    
    if (iOS8Later) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            if (groupName) {
                PHAssetCollection *collection = [self fetchCollectionWithGroupName:groupName];
                PHAssetCollectionChangeRequest *collectionRequest;
                if (collection) {
                    collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                }else {
                   collectionRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:groupName];
                }
                PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
                [collectionRequest addAssets:@[placeHolder]];
            }else {
                NSData *data = UIImageJPEGRepresentation(image, 0.9);
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                options.shouldMoveFile = YES;
                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
            }
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (success && completion) {
                    if (completion) completion(YES);
                } else if (error) {
                    if (completion) completion(NO);
                }
            });
        }];
    } else {
        __weak typeof (self)weakSelf = self;
        [self.assetLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(NSInteger)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
            if (groupName) {
                if (error) {
                    if (completion) completion(NO);
                } else {
                    if (completion) completion(YES);
                }
            }else {
                [weakSelf.assetLibrary addAssetsGroupAlbumWithName:groupName resultBlock:^(ALAssetsGroup *group) {
                    if (group) {
                        //如果group不为空 表明新创建一个 ALAssetsGroup
                        [weakSelf.assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                            //添加资源
                            [group addAsset:asset];
                            if (completion) completion(YES);
                        } failureBlock:^(NSError *error) {
                            if (completion) completion(NO);
                        }];
                    }else {
                        //如果group为空 表明系统内已经有一个 ALAssetsGroup
                        [weakSelf.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                            NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
                            if ([groupName isEqualToString:groupName]) {
                                [weakSelf.assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                                    [group addAsset:asset];
                                    if (completion) completion(YES);
                                } failureBlock:^(NSError *error) {
                                    if (completion) completion(NO);
                                }];
                            }
                        } failureBlock:^(NSError *error) {
                            if (completion) completion(NO);
                        }];
                    }
                } failureBlock:^(NSError *error) {
                    if (completion) completion(NO);
                }];
            }
        }];
    }
}


/**
 *  保存照片到相机
 *
 *  @param image      图片
 *  @param completion 回调
 */
- (void)savePhotoToCameraRollWithImage:(UIImage *)image completion:(void (^)(BOOL isSuccess))completion {
    [self savePhotoWithImage:image groupName:nil completion:completion];
}



/**
 *  获取照片的唯一标识
 *
 *  @param asset GGAssetModel
 *
 *  @return 标识
 */
- (NSString *)getAssetIdentifier:(GGAssetModel *)assetModel {
    id asset = assetModel.asset;
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        return phAsset.localIdentifier;
    }else {
        ALAsset *alAsset = (ALAsset *)asset;
        NSURL *assetUrl = [alAsset valueForProperty:ALAssetPropertyAssetURL];
        return assetUrl.absoluteString;
    }
}






#pragma mark -
#pragma mark - 私有方法


- (PHImageRequestID)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    CGFloat fullScreenWidth = GGWindowWidth;
    if (fullScreenWidth > self.photoPreviewMaxWidth) {
        fullScreenWidth = self.photoPreviewMaxWidth;
    }
    return [self getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion];
}
- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        CGSize imageSize;
        if (photoWidth < GGWindowWidth && photoWidth < self.photoPreviewMaxWidth) {
            imageSize = CGSizeMake(photoWidth * GGScreenScale, photoWidth * GGScreenScale);
        }else {
            PHAsset *phAsset = (PHAsset *)asset;
            CGFloat aspecRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
            CGFloat pixeWidth = photoWidth * GGScreenScale;
            CGFloat pixeHeight = photoWidth / aspecRatio;
            imageSize = CGSizeMake(pixeWidth, pixeHeight);
        }
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        PHImageRequestID imageRequestId = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                result = [self fixOrientation:result];
                if (completion) {
                    completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                }
            }
            if ([info objectForKey:PHImageResultIsInCloudKey] && !result) {
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
                option.networkAccessAllowed = YES;
                option.resizeMode = PHImageRequestOptionsResizeModeFast;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1];
                    resultImage = [self scaleImage:resultImage toSize:imageSize];
                    if (resultImage) {
                        resultImage = [self fixOrientation:resultImage];
                        if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    }
                }];
            }
        }];
        return imageRequestId;
    }else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            CGImageRef thumbnailImageRef = alAsset.thumbnail;
            UIImage *thunbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:2.0 orientation:UIImageOrientationUp];
            dispatch_async(dispatch_get_main_queue(), ^{
               
                if (completion) {
                    completion(thunbnailImage,nil,NO);
                }
                //查原图
                if (photoWidth == GGWindowWidth || photoWidth == self.photoPreviewMaxWidth) {
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
                        CGImageRef fullScrennImageRef = [assetRep fullScreenImage];
                        UIImage *fullScrennImage = [UIImage imageWithCGImage:fullScrennImageRef scale:2.0 orientation:UIImageOrientationUp];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(fullScrennImage,nil,NO);
                            }
                        });
                    });
                }
            });
        });
    }
    
    
    return 0;
}
- (void)getOriginalPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
        option.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                result = [self fixOrientation:result];
                if (completion) completion(result,info);
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            CGImageRef originalImageRef = [assetRep fullResolutionImage];
            UIImage *originalImage = [UIImage imageWithCGImage:originalImageRef scale:1.0 orientation:UIImageOrientationUp];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(originalImage,nil);
            });
        });
    }
}

/**
 *  获取相册名为 groupName 的 PHAssetCollection  实例
 *
 *  @param groupName 相册名
 *
 *  @return
 */
- (PHAssetCollection *)fetchCollectionWithGroupName:(NSString *)groupName {
    PHAssetCollectionSubtype smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumVideos;
    if (iOS9Later) {
        smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumScreenshots | PHAssetCollectionSubtypeSmartAlbumSelfPortraits | PHAssetCollectionSubtypeSmartAlbumVideos;
    }
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:smartAlbumSubtype options:nil];
    PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular | PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        NSString *name = collection.localizedTitle;
        if ([name isEqualToString:groupName]) {
            return collection;
        }
    }
    for (PHAssetCollection *collection in albums) {
        NSString *name = collection.localizedTitle;
        if ([name isEqualToString:groupName]) {
            return collection;
        }
    }
    return nil;
}




/**
 *  创建 GGAlbumModel
 *
 *  @param result < PHFetchResult<PHAsset> 或者 ALAssetsGroup<ALAsset>  资源集合
 *  @param name   相册名字
 *
 *  @return GGAlbumModel
 */
- (GGAlbumModel *)modelWithResult:(id)result name:(NSString *)name album:(id)album {
    GGAlbumModel *model = [[GGAlbumModel alloc] init];
    model.album = album;
    model.name = [self getNewAlbumName:name];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        model.count = fetchResult.count;
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        model.count = [group numberOfAssets];
    }
    return model;
}

- (NSString *)getNewAlbumName:(NSString *)name {
    if (iOS8Later) {
        NSString *newName;
        if ([name rangeOfString:@"Roll"].location != NSNotFound)         newName = @"相机胶卷";
        else if ([name rangeOfString:@"Stream"].location != NSNotFound)  newName = @"我的照片流";
        else if ([name rangeOfString:@"Added"].location != NSNotFound)   newName = @"最近添加";
        else if ([name rangeOfString:@"Selfies"].location != NSNotFound) newName = @"自拍";
        else if ([name rangeOfString:@"shots"].location != NSNotFound)   newName = @"截屏";
        else if ([name rangeOfString:@"Videos"].location != NSNotFound)  newName = @"视频";
        else if ([name rangeOfString:@"Panoramas"].location != NSNotFound)  newName = @"全景照片";
        else if ([name rangeOfString:@"Favorites"].location != NSNotFound)  newName = @"个人收藏";
        else if ([name rangeOfString:@"All Photos"].location != NSNotFound)  newName = @"所有照片";
        else newName = name;
        return newName;
    } else {
        return name;
    }
}
- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

- (BOOL)hasSubString:(NSString *)str subStr:(NSString *)subStr {
    if (iOS8Later) {
        return [str containsString:subStr];
    }else {
        NSRange range = [str rangeOfString:subStr];
        return range.location != NSNotFound;
    }
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    if (!self.shouldFixOrientation) return aImage;
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    if (image.size.width > size.width) {
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    } else {
        return image;
    }
}


- (void)callBackAllAlbums:(NSArray<GGAlbumModel *>*)albums Completion:(void (^)(NSArray<GGAlbumModel *> *models))completion {
    if (self.albumLoadOverCount == 0) {
        if (completion) completion(albums);
    }
}





@end
