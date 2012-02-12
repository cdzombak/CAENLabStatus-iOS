#import <UIKit/UIKit.h>

#import "PullRefreshTableViewController.h"

@class DZCDataController;

@interface DZCLabsViewController : PullRefreshTableViewController

@property(nonatomic, strong) DZCDataController *dataController;

- (void)refreshData;

@end
