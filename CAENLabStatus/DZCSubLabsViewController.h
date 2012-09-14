#import <UIKit/UIKit.h>

@class DZCLab;
@class DZCDataController;

@interface DZCSubLabsViewController : UITableViewController

@property (nonatomic, readonly, strong) DZCLab *lab;
@property (nonatomic, strong) DZCDataController *dataController;

- (id)initWithLab:(DZCLab *)lab;

@end
