#import "DZCAppDelegate.h"
#import "DZCDataController.h"
#import "DZCLabsListViewController.h"
#import "UIColor+DZCColors.h"
#import "AFNetworkActivityIndicatorManager.h"

static const NSTimeInterval DZCAppBackgroundRefreshTimeout = 60.0;

@interface DZCAppDelegate ()

@property (nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, strong) DZCDataController *dataController;
@property (nonatomic, strong) DZCLabsListViewController *labsViewController;

@property (nonatomic, strong) NSDate *appBackgroundTime;

@end

@implementation DZCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setTintColor:[UIColor dzc_logoBlueColor]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.labsViewController = [[DZCLabsListViewController alloc] init];
        self.labsViewController.dataController = self.dataController;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.labsViewController];
        self.rootViewController = navController;
    } else {
        //self.rootViewController = [[DZCRootViewController alloc] initWithNibName:@"DZCRootViewController_iPad" bundle:nil];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    self.appBackgroundTime = [NSDate date];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.appBackgroundTime && [[NSDate date] timeIntervalSinceDate:self.appBackgroundTime] > DZCAppBackgroundRefreshTimeout) {
        [self.dataController clearCache];
        [self.dataController reloadLabStatusesWithBlock:nil];
        
        [self.labsViewController refreshData];
    }
}

#pragma mark - Property overrides

- (DZCDataController *)dataController
{
    if (!_dataController) {
        _dataController = [[DZCDataController alloc] init];
    }
    return _dataController;
}

@end
