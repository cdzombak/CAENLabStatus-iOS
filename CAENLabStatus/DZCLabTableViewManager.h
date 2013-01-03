#import <UIKit/UIKit.h>

@class DZCDataController;
@class DZCLab;

@interface DZCLabTableViewManager : NSObject <UITableViewDataSource, UITableViewDelegate>

/**
 * Designated factory method.
 */
+ (DZCLabTableViewManager *)tableViewManagerForLab:(DZCLab *)lab dataController:(DZCDataController *)dataController;
+ (UITableViewStyle)tableViewStyleForLab:(DZCLab *)lab;

@property (nonatomic, weak) UINavigationController *detailNavController;

@property (nonatomic, readonly, strong) DZCLab *lab;
@property (nonatomic, readonly, strong) DZCDataController *dataController;

- (void)configureTableView:(UITableView *)tableView;

- (void)prepareData;

@end
