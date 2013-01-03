#import "DZCAppDelegate.h"
#import "DZCDataController.h"
#import "DZCLabsListViewController.h"
#import "UIColor+DZCColors.h"

@interface DZCAppDelegate ()

@property (nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, strong) DZCDataController *dataController;
@property (nonatomic, strong) DZCLabsListViewController *labsViewController;

@property (nonatomic, assign) BOOL appWasInBackground;

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
    
    self.appWasInBackground = NO;

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    self.appWasInBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.appWasInBackground) {
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
