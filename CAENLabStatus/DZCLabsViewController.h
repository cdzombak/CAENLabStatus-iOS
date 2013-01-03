#import <UIKit/UIKit.h>

@class DZCDataController;

@interface DZCLabsViewController : UITableViewController

@property(nonatomic, strong) DZCDataController *dataController;

/**
 * Designated initializer
 */
- (id)init;

- (void)refreshData;

@end
