#import "DZCSubLabsViewController.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "SRRefreshView.h"

@interface DZCSubLabsViewController () <SRRefreshDelegate>

@property (nonatomic, strong) NSMutableArray *labs;
@property (nonatomic, weak) SRRefreshView *slimeRefreshView;

- (void)refreshData;
- (void)loadData;

@end

@implementation DZCSubLabsViewController

@synthesize lab = _lab, labs = _labs, dataController = _dataController;

- (id)initWithLab:(DZCLab *)lab
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _lab = lab;
    }
    return self;
}

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    SRRefreshView *slimeRefreshView = [[SRRefreshView alloc] init];
    slimeRefreshView.delegate = self;
    slimeRefreshView.upInset = 47;
    slimeRefreshView.slimeMissWhenGoingBack = YES;
    [self.tableView addSubview:slimeRefreshView];
    self.slimeRefreshView = slimeRefreshView;

    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.rowHeight = 55.0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = self.lab.humanName;
    
    [self loadData];
}

#pragma mark - SRRefreshDelegate methods

- (void)slimeRefreshStartRefresh:(SRRefreshView *)refreshView
{
    [self refreshData];
}

#pragma mark - Data managament

- (void)refreshData
{
    [self.dataController clearCache];
    [self loadData];
}

- (void)loadData
{
    self.labs = nil;
    
    for (DZCLab *lab in self.lab.subLabs) {
        [self.labs addObject:lab];
    }
    
    [self.labs sortUsingSelector:@selector(compareHumanName:)];
    
    [self.slimeRefreshView endRefresh];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate methods

#pragma mark Slime-related

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.slimeRefreshView scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.slimeRefreshView scrollViewDidEndDraging];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.labs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if ([self.labs count] < indexPath.row+1) {
        return cell;
    }
    
    DZCLab *lab = [self.labs objectAtIndex:indexPath.row];
    
    cell.textLabel.text = lab.humanName;

    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    cell.detailTextLabel.text = @"...";
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
    
    [self.dataController machineCountsInLab:lab withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {
        if (error) {
            cell.detailTextLabel.text = @"...";
            return;
        }

        NSInteger freeCount = [total intValue] - [used intValue];
        float usedPercent = [used floatValue] / [total floatValue];
        float freePercent = 1.0 - usedPercent;

        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d (%d%%) free", freeCount, (int)roundf(freePercent*100)];

        if (usedPercent >= 0.9) {
            cell.detailTextLabel.font = [UIFont systemFontOfSize:17.0];
        } else {
            cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:17.0];
        }
    }];

    return cell;
}

#pragma mark - Property overrides

- (NSMutableArray *)labs {
    if (!_labs) {
        _labs = [NSMutableArray array];
    }
    return _labs;
}

@end
