//
//  SuperFlingTableViewCell.h
//  superfling
//
//  Created by Gary Riches on 23/09/2015.
//  Copyright (c) 2015 Gary Riches. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SuperFlingTableViewCell : UITableViewCell

@property (nonatomic) long pathID;
@property (nonatomic, strong) IBOutlet UIImageView *cellImageView;
@property (nonatomic, strong) IBOutlet UILabel *cellTitle;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *cellActivityIndicator;

@end
