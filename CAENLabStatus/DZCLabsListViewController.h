#import <UIKit/UIKit.h>

@class DZCDataController;

@interface DZCLabsListViewController : UITableViewController

@property (nonatomic, strong) DZCDataController *dataController;
@property (nonatomic, strong) UINavigationController *padDetailNavigationController;

/**
 * Designated initializer
 */
- (id)init;

- (void)refreshData;

@end
