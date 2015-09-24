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
#import "AppDelegate.h"
#import "UIImage+Resize.h"
#import <malloc/malloc.h>

// Defines for core data
#define CoreDataPathID @"pathID"
#define CoreDataTitle @"title"
#define CoreDataImageID @"imageID"
#define CoreDataIndex @"index"

// Defines for JSON
#define JSONPathID @"ID"
#define JSONTitle @"Title"
#define JSONImageID @"imageID"

// Misc defines
#define cellName @"SuperFlingTableViewCell"


// Images at your location are massive. I appreciate that you are testing what we do so I have
// made sure I resize and save a smaller version dependant on the device size.
// One other thing I would do would be to speak with the back end team and get them to
// spit out images of the maximum usable size, or better yet pass the size in and have
// them returned correctly.
// To simulate this I have resized the images for iPhone 6 Plus size (largest supported)
// but still resize them on device to demonstrate that thought and ability
#define imagePath @"http://www.bouncingball.mobi/apps/files/resized/"
#define dataPath @"http://challenge.superfling.com"

@interface ImageDisplayViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *flings;
@property (nonatomic, strong) IBOutlet UITableView *flingTableView;
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic, strong) NSString *libraryPath;
@property (nonatomic, strong) NSURLSession *imageDownloadSession;
@property (nonatomic, weak) AppDelegate *appDelegate;

@end

@implementation ImageDisplayViewController

#pragma mark - UITableView delegate methods -
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // All photos I have currently seen are 1.6:1 aspect ratio. I will take the width and divid by 1.6 then aspect fill to handle off sized images.
    float screenWidth = self.view.frame.size.width;
    float imageHeight = screenWidth / 1.6f;
    return imageHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 10)];

    [headerView setBackgroundColor:[UIColor blackColor]];

    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 4;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (self.flings) {
        return [self.flings count];
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(SuperFlingTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    int currentSection = (int)indexPath.section;
    
    NSManagedObjectContext *currentFling = self.flings[currentSection];
    
    cell.pathID = [[currentFling valueForKey:CoreDataPathID] unsignedLongLongValue];
    cell.cellTitle.text = [currentFling valueForKey:CoreDataTitle];
    cell.cellImageView.image = nil;
    [cell.cellActivityIndicator startAnimating];
    
    [self getImageWithID:[[currentFling valueForKey:CoreDataPathID] unsignedLongLongValue] forCell:cell];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellIdentifier = cellName;
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
                                                               NSArray *flings = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                                               
                                                               // Array memory size sits around 15KB for 300 entries. This is fine to manage a much larger array.
                                                               // Scale shoulnd't be a problem
                                                               //NSLog(@"size of Object: %zd", malloc_size((__bridge const void *)(flings)));
                                                               //NSLog(@"size of Object: %zd", malloc_size((__bridge const void *)(flings[0])));
                                                               
                                                               // Loop through array and create core data entires
                                                               NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Fling" inManagedObjectContext:self.appDelegate.managedObjectContext];
                                                               
                                                               for (int i = 0; i < flings.count; i++) {
                                                                   
                                                                   NSManagedObject *newFling = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.appDelegate.managedObjectContext];
                                                                   
                                                                   // Get the parsed dictionary
                                                                   NSDictionary *dictionary = flings[i];
                                                                   
                                                                   int64_t imageID = [dictionary[JSONImageID] unsignedLongLongValue];
                                                                   int64_t pathID = [dictionary[JSONPathID] unsignedLongLongValue];
                                                                   
                                                                   [newFling setValue:[NSNumber numberWithLong:imageID] forKey:CoreDataImageID];
                                                                   [newFling setValue:[NSNumber numberWithLong:pathID] forKey:CoreDataPathID];
                                                                   [newFling setValue:dictionary[JSONTitle] forKey:CoreDataTitle];
                                                                   [newFling setValue:[NSNumber numberWithUnsignedLongLong:i] forKey:CoreDataIndex];
                                                               }
                                                               
                                                               NSError *error = nil;
                                                               
                                                               if (![self.appDelegate.managedObjectContext save:&error]) {
                                                                   NSLog(@"Unable to save managed object context.");
                                                                   NSLog(@"%@, %@", error, error.localizedDescription);
                                                               }
                                                               
                                                               // Store the core data values to the array
                                                               self.flings = [self resultsFromCoreData];
                                                               
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   
                                                                   [self.flingTableView reloadData];
                                                               });
                                                           }
                                                       }
                                                   }];
    
    [downloadDataTask resume];
}

- (void)downloadImageWithIDForCell:(NSDictionary *)dictionary {
    
    unsigned long long pathID = [dictionary[CoreDataPathID] unsignedLongLongValue];
    SuperFlingTableViewCell *cell = dictionary[@"cell"];
    
    // Is this cell still on screen?
    if (pathID != cell.pathID) {

        // Cell has been scroll off screen, don't download
        return;
    }

    NSString *fullImagePath = [NSString stringWithFormat:@"%@%llu", imagePath, pathID];
    NSURL *url = [NSURL URLWithString:fullImagePath];

    NSURLSessionDownloadTask *downloadImageTask = [self.imageDownloadSession
                                                   downloadTaskWithURL:url
                                                   completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                       
                                                       if (!error) {
                                                           NSData *imageData = [NSData dataWithContentsOfURL:location];
                                                           
                                                           UIImage *downloadedImage = [UIImage imageWithData:imageData];
                                                           
                                                           float heightWidthRatio = downloadedImage.size.height / downloadedImage.size.width;
                                                           
                                                           // Reszing images to 200 height and keeping the aspect ration. Works better this way with panoramic images
                                                           CGSize resizedSize = CGSizeMake(200 / heightWidthRatio, 200);
                                                           UIImage *resizedImage = [UIImage imageWithImage:downloadedImage scaledToSize:resizedSize];
                                                           
                                                           // Save the resized file to disk
                                                           NSString *imageName = [NSString stringWithFormat:@"%llu", pathID];
                                                           NSString *pathToImage = [self.libraryPath stringByAppendingPathComponent:imageName];
                                                           
                                                           // Get the resized image data
                                                           NSData *resizedImageData = UIImageJPEGRepresentation(resizedImage, 0.5f);
                                                           [resizedImageData writeToFile:pathToImage atomically:YES];
                                                           
                                                           // Look at using NSOperationQueue for threading. GCD works with the example given but wouldn't be good
                                                           // with the log out issues the team mentioned
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               
                                                               // Is the cell still the original cell or has it been reused?
                                                               if (cell.pathID == pathID) {
                                                                   cell.cellImageView.image = resizedImage;
                                                                   [cell.cellActivityIndicator stopAnimating];
                                                               }
                                                           });
                                                       } else {
                                                        
                                                           NSLog(@"%@", [error localizedDescription]);
                                                           
                                                           // TODO: Substitute a place holder image
                                                       }
                                                   }];
    downloadImageTask.priority = 1;
    
    [downloadImageTask resume];
}

#pragma mark - Helper methods -
- (NSArray *)resultsFromCoreData {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Fling" inManagedObjectContext:self.appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:CoreDataIndex ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    NSArray *result = [self.appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Unable to execute fetch request.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        
    } else {
        
        if (result.count) {

            return result;
        }
    }
    
    return nil;
}

// This method will either pull from the cache or start a download
- (void)getImageWithID:(uint64_t)pathID forCell:(SuperFlingTableViewCell *)cell {
    
    // Does the file exist in the library?
    NSString *imageName = [NSString stringWithFormat:@"%llu", pathID];
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
                    [cell.cellActivityIndicator stopAnimating];
                }
            });
        });
    } else {
        
        // Adding a timer here so only cells that are on screen for a period of time initiate a download.
        // This stops a brisk scroll downloading images that don't need to be fetched yet
        [self performSelector:@selector(downloadImageWithIDForCell:) withObject:@{CoreDataPathID: [NSNumber numberWithUnsignedLongLong:pathID], @"cell": cell} afterDelay:0.2 inModes:@[NSRunLoopCommonModes]];
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
    [self checkReachabilityAndDownloadIfRequired];
}

- (void)checkReachabilityAndDownloadIfRequired {
    
    // Fetch the list of flings if we have an internet connection, else display a message if no content or show old content
    NetworkStatus netStatus = [self.hostReachability currentReachabilityStatus];
    
    NSArray *cachedData = [self resultsFromCoreData];
    
    switch (netStatus)
    {
        case NotReachable:        {
            
            // Do we have cached data?
            if (cachedData) {
                
                // Already have data so just reload the table view and remove the notification
                [self.hostReachability stopNotifier];
                
                self.flings = cachedData;
                [self.flingTableView reloadData];
            } else {
             
                // No connection and no cached data, wait for connection and show spinner.
            }
            break;
        }
            
        case ReachableViaWWAN:
        case ReachableViaWiFi:        {
            
            [self.hostReachability stopNotifier];
            
            // If no data then download new data. Assuming the data isn't changing for the purpose of the demo as I see no timestamps
            // Do we have cached data?
            if (cachedData) {
                
                // Existing data, store in array
                self.flings = cachedData;
                [self.flingTableView reloadData];
            } else {
                
                [self downloadAndParseListOfFlings];
            }
            
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
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
    
    self.libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    // Register the nib for the table view cells
    [self.flingTableView registerNib:[UINib nibWithNibName:cellName bundle:nil] forCellReuseIdentifier:cellName];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.hostReachability = [Reachability reachabilityWithHostName:@"challenge.superfling.com"];
    [self.hostReachability startNotifier];
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 4;
    sessionConfiguration.timeoutIntervalForResource = 120;
    sessionConfiguration.timeoutIntervalForRequest = 300;
    self.imageDownloadSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    [self checkReachabilityAndDownloadIfRequired];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
