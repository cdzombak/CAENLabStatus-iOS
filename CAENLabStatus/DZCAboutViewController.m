#import "DZCAboutViewController.h"

@implementation DZCAboutViewController

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"About", nil);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
