#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"

@class DZCLab;
@class DZCDataController;

@interface DZCSubLabsViewController : PullRefreshTableViewController

@property (nonatomic, readonly, strong) DZCLab *lab;
@property (nonatomic, strong) DZCDataController *dataController;

- (id)initWithLab:(DZCLab *)lab;

@end
