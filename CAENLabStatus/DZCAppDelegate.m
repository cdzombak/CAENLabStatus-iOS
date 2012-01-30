#import "DZCAppDelegate.h"
#import "DZCDataController.h"
#import "DZCLabsViewController.h"

@interface DZCAppDelegate ()

@property (nonatomic, strong) DZCDataController *dataController;
@property (nonatomic, assign) BOOL appWasInBackground;

@end

@implementation DZCAppDelegate

@synthesize window = _window, rootViewController = _viewController, dataController = _dataController, appWasInBackground = _appWasInBackground;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        DZCLabsViewController *labsViewController = [[DZCLabsViewController alloc] initWithStyle:UITableViewStylePlain];
        labsViewController.dataController = self.dataController;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:labsViewController];
        
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
        [self.dataController reloadLabStatusesWithBlock:nil];
        [self.dataController clearHostInfoCache];
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
