//
//  ViewController.m
//  superfling
//
//  Created by Gary Riches on 22/09/2015.
//  Copyright (c) 2015 Gary Riches. All rights reserved.
//

#import "ImageDisplayViewController.h"
#import "SuperFlingTableViewCell.h"
#import "Reachability.h"

#define imagePath @"http://challenge.superfling.com/photos/"
#define dataPath @"http://challenge.superfling.com"

@interface ImageDisplayViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *flings;
@property (nonatomic, strong) IBOutlet UITableView *flingTableView;
@property (nonatomic) Reachability *hostReachability;

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
- (void)downloadAndParseListOfFlings {
    
    NSURL *url = [NSURL URLWithString:dataPath];
    
    NSURLSessionDataTask *downloadDataTask = [[NSURLSession sharedSession]
                                                   dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                       
                                                       if (error) {
                                                           NSLog(@"%@", [error localizedDescription]);
                                                           
                                                           [self showErrorAlert];
                                                       } else {
                                                           
                                                           // Parse and store in to core data
                                                           // Working with just array first. Will save to CoreData once tableview is working
                                                           self.flings = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                                           
                                                           if (error) {
                                                               NSLog(@"JSON issue. Check JSON validity: %@", [error localizedDescription]);
                                                               
                                                               [self showErrorAlert];
                                                           }
                                                       }
                                                   }];
    
    [downloadDataTask resume];
}

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

#pragma mark - UI methods -
- (void)showErrorAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"Something went wrong. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Reachability methods -
- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self downloadAndParseListOfFlings];
}

- (void)checkReachabilityAndDownloadIfRequired {
    
    // Fetch the list of flings if we have an internet connection, else display a message if no content or show old content
    NetworkStatus netStatus = [self.hostReachability currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:        {
            
            // Do we have cached data?
            
            break;
        }
            
        case ReachableViaWWAN:
        case ReachableViaWiFi:        {
            
            // If no data then download new data. Assuming the data isn;t changing for the purpose of the demo as I see no timestamps
            [self downloadAndParseListOfFlings];
            
            break;
        }
    }
}

#pragma mark - Boilerplate -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.hostReachability = [Reachability reachabilityWithHostName:dataPath];
    [self.hostReachability startNotifier];
    
    [self checkReachabilityAndDownloadIfRequired];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
