#import "DZCAboutViewController.h"

@implementation DZCAboutViewController

@synthesize appVersionLabel = _appVersionLabel;

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"About", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        self.appVersionLabel.alpha = 0.0;
    } else {
        self.appVersionLabel.alpha = 1.0;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [UIView animateWithDuration:duration animations:^{
            self.appVersionLabel.alpha = 0.0;
        }];
    } else {
        [UIView animateWithDuration:duration animations:^{
            self.appVersionLabel.alpha = 1.0;
        }];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload {
    [self setView:nil];
    [self setAppVersionLabel:nil];
    [super viewDidUnload];
}

#pragma mark - Buttons

- (IBAction)pressedReportProblemButton:(id)sender {
    NSString *problemReportEmail = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@",
                                    [@"cdzombak@umich.edu" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                    [@"CAEN Lab Status App Feedback" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: problemReportEmail]];
}

- (IBAction)pressedProjectPageButton:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://github.com/cdzombak/CAENLabStatus-iOS"]];
}

@end
