# PhotoManager
一个简单的照片获取库，可以快速的获取照片、相册。使用简单。

### API:

	/**
	 *  获取相机相册
	 *
	 *  @param allowPickingVideo 是否包含视频
	 *  @param allowPickingImage 是否包含图片
	 *  @param completion        回调
	 */
	- (void)getCameraRollAlbum:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(GGAlbumModel *model))completion;
	/**
	 *  获取所有的相册
	 *
	 *  @param allowPickingVideo 是否包含视频
	 *  @param allowPickingImage 是否包含图片
	 *  @param completion        回调
	 */
	- (void)getAllAlbums:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<GGAlbumModel *> *models))completion;
	
	
	/**
	 *  获取相册下的资源数组
	 *
	 *  @param albumModel        相册对象
	 *  @param allowPickingVideo 是否包含视频
	 *  @param allowPickingImage 是否包含图片
	 *  @param completion        回调 NSArray<GGAssetModel *>
	 */
	- (void)getAssetsFromFetchAlbumModel:(GGAlbumModel *)albumModel allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<GGAssetModel *> *models))completion;
	
	/**
	 *  获取某个相册某个下标的资源
	 *
	 *  @param albumModel        相册对象
	 *  @param index             下标
	 *  @param allowPickingVideo 是否包含视频
	 *  @param allowPickingImage 是否包含图片
	 *  @param completion        回调 GGAssetModel
	 */
	- (void)getAssetFromFetchAlbumModel:(GGAlbumModel *)albumModel atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(GGAssetModel *model))completion;
	
	
	/**
	 *  获取封面图片
	 *
	 *  @param model      GGAlbumModel
	 *  @param completion 回调
	 */
	- (void)getCoverImageWithAlbumModel:(GGAlbumModel *)model completion:(void (^)(UIImage *coverImage))completion;
	
	/**
	 *  获取照片本身
	 *
	 *  @param asset      GGAssetModel
	 *  @param completion 回调  isDegraded:是否是缩略图
	 *
	 *  @return PHImageRequestID
	 */
	- (PHImageRequestID)getPhotoWithAssetModel:(GGAssetModel *)assetModel completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;
	/**
	 *  获取一定宽高的正方形图片
	 *
	 *  @param assetModel GGAssetModel
	 *  @param photoWidth 宽
	 *  @param completion 回调 isDegraded:是否是缩略图
	 *
	 *  @return PHImageRequestID
	 */
	- (PHImageRequestID)getPhotoWithAssetModel:(GGAssetModel *)assetModel photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;
	/**
	 *  获取原图
	 *
	 *  @param assetModel GGAssetModel
	 *  @param completion 回调 isDegraded:是否是缩略图
	 */
	- (void)getOriginalPhotoWithAssetModel:(GGAssetModel *)assetModel completion:(void (^)(UIImage *photo,NSDictionary *info))completion;
	
	
	
	/**
	 *  保存照片到指定相册
	 *
	 *  @param image      图片
	 *  @param groupName  相册名
	 *  @param completion 回调
	 */
	- (void)savePhotoWithImage:(UIImage *)image groupName:(NSString *)groupName completion:(void (^)(BOOL isSuccess))completion;
	
	
	/**
	 *  保存照片到相机
	 *
	 *  @param image      图片
	 *  @param completion 回调
	 */
	- (void)savePhotoToCameraRollWithImage:(UIImage *)image completion:(void (^)(BOOL isSuccess))completion;
	





<div align=center>
<img src="https://github.com/guiyongdong/Resource/blob/master/hexoImage/PhotoManager.gif?raw=true"/>
</div>
