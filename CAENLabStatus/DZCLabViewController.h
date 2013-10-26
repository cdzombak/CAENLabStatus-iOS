@class DZCLab;
@class DZCDataController;

@interface DZCLabViewController : UIViewController

@property (nonatomic, strong) DZCDataController *dataController;
@property (nonatomic, strong) UINavigationController *padDetailNavigationController;

@property (nonatomic, readonly, strong) DZCLab *lab;

- (id)initWithLab:(DZCLab *)lab;

@end
