#import <UIKit/UIKit.h>

@interface DZCAboutViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *appVersionLabel;

- (IBAction)pressedReportProblemButton:(id)sender;
- (IBAction)pressedProjectPageButton:(id)sender;

@end
