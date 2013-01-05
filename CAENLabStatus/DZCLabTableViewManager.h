#import <UIKit/UIKit.h>

@class DZCDataController;
@class DZCLab;

@interface DZCLabTableViewManager : NSObject <UITableViewDataSource, UITableViewDelegate>

/**
 * Designated factory method.
 */
+ (DZCLabTableViewManager *)tableViewManagerForLab:(DZCLab *)lab dataController:(DZCDataController *)dataController;
+ (UITableViewStyle)tableViewStyleForLab:(DZCLab *)lab;

@property (nonatomic, copy) void(^vcPushBlock)(UIViewController *vc);

@property (nonatomic, readonly, strong) DZCLab *lab;
@property (nonatomic, readonly, strong) DZCDataController *dataController;

- (void)configureTableView:(UITableView *)tableView;

- (void)prepareData;

@end
