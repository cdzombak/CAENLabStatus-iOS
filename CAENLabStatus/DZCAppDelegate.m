#import "DZCAppDelegate.h"
#import "DZCDataController.h"
#import "DZCLabsListViewController.h"
#import "DZCEmptyDetailViewController.h"
#import "UIColor+DZCColors.h"
#import "AFNetworkActivityIndicatorManager.h"

static const NSTimeInterval DZCAppBackgroundRefreshTimeout = 60.0;

@interface DZCAppDelegate ()

@property (nonatomic, strong) DZCDataController *dataController;
@property (nonatomic, strong) DZCLabsListViewController *labsViewController;

@property (nonatomic, strong) NSDate *appBackgroundTime;

@end

@implementation DZCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setTintColor:[UIColor dzc_logoBlueColor]];

    UIViewController *rootVC;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.labsViewController = [[DZCLabsListViewController alloc] init];
        rootVC = [[UINavigationController alloc] initWithRootViewController:self.labsViewController];
    } else { // UIUserInterfaceIdiomPad
        UISplitViewController *vc = [[UISplitViewController alloc] init];
        DZCEmptyDetailViewController *emptyVC = [[DZCEmptyDetailViewController alloc] init];
        emptyVC.dataController = self.dataController;
        UINavigationController *detailNavigationVC = [[UINavigationController alloc] initWithRootViewController:emptyVC];
        self.labsViewController = [[DZCLabsListViewController alloc] init];
        self.labsViewController.padDetailNavigationController = detailNavigationVC;
        vc.viewControllers = @[
                               [[UINavigationController alloc] initWithRootViewController:self.labsViewController],
                               detailNavigationVC
                               ];
        vc.delegate = self;
        rootVC = vc;
    }

    self.labsViewController.dataController = self.dataController;
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];

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

#pragma mark UISplitViewControllerDelegate methods

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    // nope, just keep both VCs visible always.
    return NO;
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
