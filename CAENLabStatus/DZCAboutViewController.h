#import <UIKit/UIKit.h>

@interface DZCAboutViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;

@property (weak, nonatomic) IBOutlet UIButton *reportProblemButton;
@property (weak, nonatomic) IBOutlet UIButton *projectPageButton;

- (IBAction)pressedReportProblemButton:(id)sender;
- (IBAction)pressedProjectPageButton:(id)sender;

@end
