//
//  UIImage+Resize.h
//  superfling
//
//  Created by Gary Riches on 23/09/2015.
//  Copyright (c) 2015 Gary Riches. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

+ (UIImage *)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end
