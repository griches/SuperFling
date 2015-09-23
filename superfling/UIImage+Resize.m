//
//  UIImage+Resize.m
//  superfling
//
//  Created by Gary Riches on 23/09/2015.
//  Copyright (c) 2015 Gary Riches. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

+ (UIImage *)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
