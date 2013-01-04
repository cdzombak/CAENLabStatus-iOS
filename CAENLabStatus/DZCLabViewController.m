#import "DZCLabViewController.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "UIColor+DZCColors.h"
#import "DZCLabTableViewManager.h"
#import "CDZTableViewSplitDelegate.h"

@interface DZCLabViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) DZCLabTableViewManager *tvManager;
@property (nonatomic, strong) CDZTableViewSplitDelegate *tvSplitDelegate;

@end

@implementation DZCLabViewController

- (id)initWithLab:(DZCLab *)lab
{
    self = [super init];
    if (self) {
        _lab = lab;
        self.title = self.lab.humanName;
    }
    return self;
}

// display map + sublabs if so, plain
// display map + groups ( usage , hosts ) otherwise

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;

    UITableViewStyle tvStyle = [DZCLabTableViewManager tableViewStyleForLab:self.lab];
    self.tableView = [[UITableView alloc] initWithFrame:(CGRect){CGPointZero, self.view.bounds.size} style:tvStyle];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.tableView];

    self.tvManager = [DZCLabTableViewManager tableViewManagerForLab:self.lab dataController:self.dataController];
    self.tvManager.detailNavController = self.navigationController;
    [self.tvManager configureTableView:self.tableView];
    self.tvSplitDelegate = [[CDZTableViewSplitDelegate alloc] initWithScrollViewDelegate:self tableViewDelegate:self.tableView.delegate];
    self.tableView.delegate = self.tvSplitDelegate;

    [self.tvManager prepareData];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if (selectedIndexPaths.count) {
        for (NSIndexPath *indexPath in selectedIndexPaths) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView flashScrollIndicators];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - Property overrides

// n/a

@end
