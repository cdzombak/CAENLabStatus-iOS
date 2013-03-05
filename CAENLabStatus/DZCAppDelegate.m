#import "DZCAppDelegate.h"
#import "DZCDataController.h"
#import "DZCLabsListViewController.h"
#import "UIColor+DZCColors.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "iRate.h"

static const NSTimeInterval DZCAppBackgroundRefreshTimeout = 60.0;

@interface DZCAppDelegate ()

@property (nonatomic, strong) DZCDataController *dataController;
@property (nonatomic, strong) DZCLabsListViewController *labsViewController;

@property (nonatomic, strong) NSDate *appBackgroundTime;

@end

@implementation DZCAppDelegate

+ (void)initialize
{
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 10;
    [iRate sharedInstance].remindPeriod = 2;
    [iRate sharedInstance].promptAgainForEachNewVersion = NO;
    [iRate sharedInstance].onlyPromptIfLatestVersion = YES;
    [iRate sharedInstance].applicationName = NSLocalizedString(@"CAEN Labs", nil);
    [iRate sharedInstance].message = NSLocalizedString(@"Is this app useful? Could you help me out by rating it in the App Store? It'll just take a minute. Thanks!", nil);
    [iRate sharedInstance].disableAlertViewResizing = NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setTintColor:[UIColor dzc_logoBlueColor]];

    UIViewController *rootVC;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.labsViewController = [[DZCLabsListViewController alloc] init];
        rootVC = [[UINavigationController alloc] initWithRootViewController:self.labsViewController];
    } else { // UIUserInterfaceIdiomPad
        UISplitViewController *vc = [[UISplitViewController alloc] init];
        UIViewController *emptyVC = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
