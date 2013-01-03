#import "DZCLabViewController.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "UIColor+DZCColors.h"
#import "DZCLabTableViewManager.h"

@interface DZCLabViewController ()

@property (nonatomic, strong) DZCLabTableViewManager *tvManager;

@end

@implementation DZCLabViewController

- (id)initWithLab:(DZCLab *)lab
{
    UITableViewStyle tvStyle = [DZCLabTableViewManager tableViewStyleForLab:lab];
    self = [super initWithStyle:tvStyle];
    if (self) {
        _lab = lab;
        self.title = self.lab.humanName;
    }
    return self;
}

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tvManager = [DZCLabTableViewManager tableViewManagerForLab:self.lab dataController:self.dataController];
    self.tvManager.detailNavController = self.navigationController;
    [self.tvManager configureTableView:self.tableView];

    // display map + sublabs if so, plain
    // display map + groups ( usage , hosts ) otherwise

    [self.tvManager prepareData];
    [self.tableView reloadData];
}

#pragma mark - Property overrides

// n/a

@end
