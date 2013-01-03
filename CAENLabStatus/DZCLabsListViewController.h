#import <UIKit/UIKit.h>

@class DZCDataController;

@interface DZCLabsListViewController : UITableViewController

@property(nonatomic, strong) DZCDataController *dataController;

/**
 * Designated initializer
 */
- (id)init;

- (void)refreshData;

@end
