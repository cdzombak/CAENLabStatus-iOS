#import <UIKit/UIKit.h>

@class DZCLab;
@class DZCDataController;

@interface DZCLabViewController : UIViewController

@property (nonatomic, readonly, strong) DZCLab *lab;
@property (nonatomic, strong) DZCDataController *dataController;

- (id)initWithLab:(DZCLab *)lab;

@end
