#import "DZCAboutViewController.h"

@implementation DZCAboutViewController

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"About", nil);
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(pressedDoneButton:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    
    self.appVersionLabel.text = [NSString stringWithFormat:@"version %@", [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];

    self.view.backgroundColor = [UIColor underPageBackgroundColor];

    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];

    [self.reportProblemButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.reportProblemButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];

    [self.projectPageButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.projectPageButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
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

- (void)viewDidUnload {
    [self setView:nil];
    [self setAppVersionLabel:nil];
    [self setProjectPageButton:nil];
    [self setReportProblemButton:nil];
    [super viewDidUnload];
}

#pragma mark - Buttons

- (void)pressedDoneButton:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)pressedReportProblemButton:(id)sender
{
    NSString *problemReportEmail = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@",
                                    [@"cdzombak@umich.edu" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                    [@"CAEN Lab Status App Feedback" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: problemReportEmail]];
}

- (IBAction)pressedProjectPageButton:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://github.com/cdzombak/CAENLabStatus-iOS"]];
}

@end
