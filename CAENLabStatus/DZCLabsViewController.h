#import <UIKit/UIKit.h>

@class DZCDataController;

@interface DZCLabsViewController : UITableViewController

@property(nonatomic, strong) DZCDataController *dataController;

- (void)refreshData;

@end
