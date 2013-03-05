#import <UIKit/UIKit.h>

@class DZCLab;
@class DZCDataController;

@interface DZCLabViewController : UIViewController

@property (nonatomic, strong) UINavigationController *padDetailNavigationController;
@property (nonatomic, strong) DZCDataController *dataController;

@property (nonatomic, readonly, strong) DZCLab *lab;
@property (nonatomic, strong) UIImage *mapImage;

- (id)initWithLab:(DZCLab *)lab;

@end
