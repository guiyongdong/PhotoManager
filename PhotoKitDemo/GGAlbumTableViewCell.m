//
//  GGAlbumTableViewCell.m
//  PhotoKitDemo
//
//  Created by 贵永冬 on 16/11/5.
//  Copyright © 2016年 贵永冬. All rights reserved.
//

#import "GGAlbumTableViewCell.h"

@implementation GGAlbumTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.iconView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
