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
@property (nonatomic, strong) NSString *libraryPath;

@end

@implementation ImageDisplayViewController

#pragma mark - UITableView delegate methods -
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // All photos I have currently seen are 1.6:1 aspect ratio. I will take the width and divid by 1.6 then aspect fill to handle off sized images.
    float screenWidth = self.view.frame.size.width;
    float imageHeight = screenWidth / 1.6f;
    return imageHeight;
}

// Leaving in for a little flair if possible later
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    [self deselectSelectedCell];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.flings) {
        return [self.flings count];
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(SuperFlingTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int currentRow = (int)indexPath.row;
    
    cell.pathID = [self.flings[currentRow][@"ID"] longValue];
    cell.cellTitle.text = self.flings[currentRow][@"Title"];
    [self getImageWithID:[self.flings[currentRow][@"ID"] longValue] forCell:cell];
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
                                                           
                                                           if (error) {
                                                               NSLog(@"JSON issue. Check JSON validity: %@", [error localizedDescription]);
                                                               
                                                               [self showErrorAlert];
                                                           } else {
                                                               
                                                               // Parse and store in to core data
                                                               // Working with just array first. Will save to CoreData once tableview is working
                                                               self.flings = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                                               
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   
                                                                   [self.flingTableView reloadData];
                                                               });
                                                           }
                                                       }
                                                   }];
    
    [downloadDataTask resume];
}

- (void)downloadImageWithID:(long)pathID forCell:(SuperFlingTableViewCell *)cell {
    
    NSString *fullImagePath = [NSString stringWithFormat:@"%@%ld", imagePath, pathID];
    NSURL *url = [NSURL URLWithString:fullImagePath];
    
    NSURLSessionDownloadTask *downloadImageTask = [[NSURLSession sharedSession]
                                                   downloadTaskWithURL:url
                                                   completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                       
                                                       if (!error) {
                                                           NSData *imageData = [NSData dataWithContentsOfURL:location];
                                                           
                                                           UIImage *downloadedImage = [UIImage imageWithData:imageData];
                                                           
                                                           // Save the file to disk
                                                           // TODO: Resize the image to device width and height to width / ratio
                                                           NSString *imageName = [NSString stringWithFormat:@"%ld", pathID];
                                                           NSString *pathToImage = [self.libraryPath stringByAppendingPathComponent:imageName];
                                                           [imageData writeToFile:pathToImage atomically:YES];
                                                           
                                                           // Look at using NSOperationQueue for threading. GCD works with the example given but wouldn't be good
                                                           // with the log out issues the team mentioned
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               
                                                               // Is the cell still the original cell or has it been reused?
                                                               if (cell.pathID == pathID) {
                                                                   cell.cellImageView.image = downloadedImage;
                                                               }
                                                           });
                                                       } else {
                                                        
                                                           NSLog(@"%@", [error localizedDescription]);
                                                           
                                                           // TODO: Substitute a place holder image
                                                       }
                                                   }];
    
    [downloadImageTask resume];
}

#pragma mark - UI methods -
// This method will either pull from the cache or start a download
- (void)getImageWithID:(long)pathID forCell:(SuperFlingTableViewCell *)cell {
    
    // Does the file exist in the library?
    NSString *imageName = [NSString stringWithFormat:@"%ld", pathID];
    NSString *pathToImage = [self.libraryPath stringByAppendingPathComponent:imageName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:pathToImage];
    
    if (fileExists) {
        
        // Look at using NSOperationQueue for threading. GCD works with the example given but wouldn't be good
        // with the log out issues the team mentioned
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           
            UIImage *localImage = [UIImage imageWithContentsOfFile:pathToImage];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Is the cell still the original cell or has it been reused?
                if (cell.pathID == pathID) {
                    cell.cellImageView.image = localImage;
                }
            });
        });
    } else {
        [self downloadImageWithID:pathID forCell:cell];
    }
}

- (void)showErrorAlert {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh no!" message:@"Something went wrong. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    });
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
-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    // Register the nib for the table view cells
    [self.flingTableView registerNib:[UINib nibWithNibName:@"SuperFlingTableViewCell" bundle:nil] forCellReuseIdentifier:@"SuperFlingTableViewCell"];
    
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
