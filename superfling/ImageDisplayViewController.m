//
//  ViewController.m
//  superfling
//
//  Created by Gary Riches on 22/09/2015.
//  Copyright (c) 2015 Gary Riches. All rights reserved.
//

#import "ImageDisplayViewController.h"
#import "SuperFlingTableViewCell.h"

#define imagePath @"http://www.challenge.superfling.com/photos/"

@interface ImageDisplayViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *flings;

@end

@implementation ImageDisplayViewController

#pragma mark - UITableView delegate methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    // All photos I have currently seen are 1.6:1 aspect ratio. I will take the width and divid by 1.6 then aspect fill to handle off sized images.
    return self.view.frame.size.width * 1.6f;
}

// Leaving in for a little flair if possible later
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    [self deselectSelectedCell];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.flings count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(SuperFlingTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
//    cell.cellTitle.text = [self.flings
//    [cell.cellImage
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellIdentifier = @"SuperFlingTableViewCell";
    SuperFlingTableViewCell *cell = (SuperFlingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    return cell;
}

#pragma mark - Download methods -
- (void)downloadImageWithID:(long)pathID forCell:(UITableViewCell *)cell {
    
    NSString *fullImagePath = [NSString stringWithFormat:@"%@%ld", imagePath, pathID];
    NSURL *url = [NSURL URLWithString:fullImagePath];
    
    NSURLSessionDownloadTask *downloadImageTask = [[NSURLSession sharedSession]
                                                   downloadTaskWithURL:url
                                                   completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                       
                                                       if (!error) {
                                                           UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
                                                       } else {
                                                        
                                                           NSLog(@"%@", [error localizedDescription]);
                                                           
                                                           // TODO: Substitute a place holder image
                                                       }
                                                   }];
    
    [downloadImageTask resume];
}

#pragma mark - Boilerplate -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
