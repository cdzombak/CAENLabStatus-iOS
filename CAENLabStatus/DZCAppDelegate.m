#import "DZCAppDelegate.h"
#import "DZCDataController.h"
#import "DZCLabsListViewController.h"
#import "UIColor+DZCColors.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "iRate.h"

static const NSTimeInterval DZCAppBackgroundRefreshTimeout = 60.0;

@interface DZCAppDelegate ()

@property (nonatomic, strong) UIViewController *rootViewController;
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
