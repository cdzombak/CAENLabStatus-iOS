#import "DZCAppDelegate.h"
#import "DZCDataController.h"
#import "DZCLabsViewController.h"

@interface DZCAppDelegate ()

@property (nonatomic, strong) DZCDataController *dataController;

@end

@implementation DZCAppDelegate

@synthesize window = _window, rootViewController = _viewController, dataController = _dataController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        DZCLabsViewController *labsViewController = [[DZCLabsViewController alloc] initWithStyle:UITableViewStylePlain];
        labsViewController.dataController = self.dataController;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:labsViewController];
        
        //navController.navigationBar.barStyle = UIBarStyleBlack;
        
        self.rootViewController = navController;
    } else {
        // TODO
        //self.rootViewController = [[DZCRootViewController alloc] initWithNibName:@"DZCRootViewController_iPad" bundle:nil];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.dataController reloadLabStatusesWithBlock:nil];
    // TODO flush hostinfo cache
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
