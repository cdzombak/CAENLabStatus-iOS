#import "DZCLabsListViewController.h"

#import "DZCDataController.h"
#import "DZCLab.h"

#import "DZCLabViewController.h"

static NSString *DZCLabsListViewControllerSortOrderPrefsKey = @"DZCLabsViewControllerSortOrder"; // TODO extract this into prefs singleton

static NSString *DZCLabsTableViewSectionTitles[DZCLabStatusCount];

__attribute__((constructor)) static void __InitTableViewStrings()
{
    @autoreleasepool {
        DZCLabsTableViewSectionTitles[DZCLabStatusOpen] = NSLocalizedString(@"Open", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusClosed] = NSLocalizedString(@"Closed", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusClosedSoon] = NSLocalizedString(@"Closed Soon", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusReservedSoon] = NSLocalizedString(@"Reserved Soon", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusPartiallyReserved] = NSLocalizedString(@"Partially Reserved", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusReserved] = NSLocalizedString(@"Reserved", nil);
    }
}

typedef NS_ENUM(NSUInteger, DZCLabsListFilter) {
    DZCLabsListFilterAll = 0,
    DZCLabsListFilterNorth,
    DZCLabsListFilterCentral,
};

@interface DZCLabsListViewController () 

@property (nonatomic, strong) NSMutableArray *labOrdering;
@property (nonatomic, strong) NSMutableDictionary *labsByStatus;
@property (nonatomic, strong) NSMutableArray *statusForTableViewSection;

@property (nonatomic, readonly) UISegmentedControl *filterControl;
@property (nonatomic, assign) DZCLabsListFilter selectedFilter;

@property (nonatomic, readonly, assign) BOOL hidesFilterBarByDefault;

@end

@implementation DZCLabsListViewController

@synthesize filterControl = _filterControl;

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"CAEN Labs", nil);
    }
    return self;
}

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Labs", nil);
    self.navigationItem.titleView = self.filterControl;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.tableView.allowsSelection = YES;
    self.tableView.rowHeight = 55.0f;

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:nil action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];

    self.labOrdering = [self retrieveSavedSortOrder];

    [self loadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    self.filterControl.enabled = !editing;
    self.filterControl.userInteractionEnabled = !editing;
}

#pragma mark - UI Actions

- (void)labListFilterControlChanged:(UISegmentedControl *)sender
{
    NSParameterAssert(sender == self.filterControl);

    self.selectedFilter = self.filterControl.selectedSegmentIndex;
    [self loadData];

    self.navigationItem.rightBarButtonItem = (self.selectedFilter == DZCLabsListFilterAll) ? self.editButtonItem : nil;

    [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top) animated:YES];
}

#pragma mark - Data Management

- (void)refreshData:(UIRefreshControl *)sender {
    [self refreshData];
}

- (void)refreshData
{
    self.labsByStatus = nil; // TODO I think this causes some interaction which can cause a crash sometimes
    [self.dataController clearCache];
    [self loadData];
}

- (void)loadData
{
    [self.dataController labsAndStatusesWithBlock:^(NSDictionary *labsResult, NSError *error) {
        
        [self.refreshControl endRefreshing];

        self.labsByStatus = nil;
        
        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Retrieving Data", nil)
                                        message:NSLocalizedString(@"Please ensure you have an Internet connection. If you do, the CAEN lab info service might be down.\n\nTry refreshing again.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"😢", nil)
                              otherButtonTitles:nil]
             show];

            self.labsByStatus = nil;
            [self.tableView reloadData];

            return;
        }

        // labsResult is a dict mapping DZCLab => (NSNumber)status
        NSMutableDictionary *filteredLabs = [NSMutableDictionary dictionary];
        [labsResult enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            BOOL includeThisLab = (self.selectedFilter == DZCLabsListFilterAll);

            DZCLab *lab = key;
            // 42.285 // todo remove hardcoded values
            BOOL isNorth = ([lab.latitude doubleValue] > 42.285);
            if (self.selectedFilter == DZCLabsListFilterNorth && isNorth) includeThisLab = YES;
            if (self.selectedFilter == DZCLabsListFilterCentral && !isNorth) includeThisLab = YES;

            if (includeThisLab) filteredLabs[key] = obj;
            
            if (stop != NULL) *stop = NO;
            return;
        }];

        NSArray* sortedLabs = [self sortedLabsFrom:[filteredLabs allKeys]];

        self.statusForTableViewSection = nil;

        for (id lab in sortedLabs) {
            DZCLabStatus status = [(NSNumber *)filteredLabs[lab] intValue];

            NSMutableArray *labs = self.labsByStatus[@(status)];
            if (!labs) {
                self.labsByStatus[@(status)] = [NSMutableArray array];
                labs = self.labsByStatus[@(status)];
            }

            [labs addObject:lab];
        }

        for (DZCLabStatus i=0; i<DZCLabStatusCount; ++i) {
            if (self.labsByStatus[@(i)] != nil) {
                [self.statusForTableViewSection addObject:@(i)];
            }
        }

        [self.tableView reloadData];
    }];
}

#pragma mark - Data helper methods

- (DZCLabStatus)statusForSection:(NSInteger)section
{
    return [self.statusForTableViewSection[(NSUInteger) section] integerValue];
}

- (DZCLab *)objectForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *statusForSection = @([self statusForSection:indexPath.section]);
    return self.labsByStatus[statusForSection][(NSUInteger) indexPath.row];
}

#pragma mark - Sorting

- (BOOL)saveSortOrder:(NSMutableArray *)sortOrder
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (!standardUserDefaults) {
        return NO;
    }
    
	[standardUserDefaults setObject:sortOrder forKey:DZCLabsListViewControllerSortOrderPrefsKey];
	[standardUserDefaults synchronize];
    
    return YES;
}

- (NSMutableArray *)retrieveSavedSortOrder
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (!standardUserDefaults) {
        return nil;
    }
    
    NSArray *resultArray = [standardUserDefaults arrayForKey:DZCLabsListViewControllerSortOrderPrefsKey];
    if (resultArray == nil) {
        return nil;
    }
    
    return [NSMutableArray arrayWithArray:resultArray];
}

- (NSArray *)sortedLabsFrom:(NSArray *)unsortedLabs
{
    NSArray *sortedLabs;

    if (!self.labOrdering) {
        sortedLabs = [unsortedLabs sortedArrayUsingSelector:@selector(compareHumanName:)];

        self.labOrdering = [NSMutableArray array];

        for (id lab in sortedLabs) {
            [self.labOrdering addObject:[lab humanName]];
        }

        [self saveSortOrder:self.labOrdering];
    } else {
        sortedLabs = [unsortedLabs sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSUInteger idx1 = [self.labOrdering indexOfObject:[obj1 humanName]];
            NSUInteger idx2 = [self.labOrdering indexOfObject:[obj2 humanName]];

            if (idx1 == NSNotFound) {
                [self.labOrdering addObject:[obj1 humanName]];
                return (NSComparisonResult)NSOrderedAscending;
            }
            if (idx2 == NSNotFound) {
                [self.labOrdering addObject:[obj2 humanName]];
                return (NSComparisonResult)NSOrderedDescending;
            }
            if (idx1 == idx2) {
                return (NSComparisonResult)NSOrderedSame;
            }
            if (idx1 > idx2) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            else {
                return (NSComparisonResult)NSOrderedAscending;
            }
        }];
    }

    return sortedLabs;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger) [self.statusForTableViewSection count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSNumber *statusForSection = @([self statusForSection:section]);
    return (NSInteger) [self.labsByStatus[statusForSection] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZCLabStatus status = [self statusForSection:indexPath.section];
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    // this is clearly here to prevent some out-of-bounds error, but I wish I'd commented better why it was necessary
    if ((NSInteger)[self.labsByStatus[@(status)] count] < indexPath.row+1) {
        return cell;
    }
    
    DZCLab *lab = [self objectForRowAtIndexPath:indexPath];

    cell.textLabel.text = lab.humanName;
    cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];

    cell.detailTextLabel.text = @"...";
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
    
    switch (status) {
        case DZCLabStatusOpen:
        case DZCLabStatusPartiallyReserved:
        case DZCLabStatusReservedSoon:
        case DZCLabStatusClosedSoon:
        {
            [self.dataController machineCountsInLab:lab withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {
                if (error) {
                    cell.detailTextLabel.text = @"...";
                    return;
                }

                NSInteger freeCount = [total intValue] - [used intValue];
                float usedPercent = [used floatValue] / [total floatValue];
                float freePercent = 1.0f - usedPercent;

                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d (%d%%) free", freeCount, (int)roundf(freePercent*100)];
                
                if (usedPercent >= 0.8f) {
                    cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
                    cell.detailTextLabel.font = [UIFont systemFontOfSize:17.0];
                } else {
                    cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
                    cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:17.0];
                }
            }];
            break;
        }
            
        case DZCLabStatusClosed:
        case DZCLabStatusReserved:
        {
            [self.dataController machineCountsInLab:lab withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {
                if (error) {
                    cell.detailTextLabel.text = @"...";
                    return;
                }
                
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d machines", [total intValue]];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
            }];
            break;
        }
            
        default: {
            NSLog(@"Unknown status encountered: %d", status);
        }
    }

    cell.showsReorderControl = (status == DZCLabStatusOpen);
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (DZCLabStatusOpen == [self statusForSection:indexPath.section]);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSParameterAssert(sourceIndexPath.section == destinationIndexPath.section);
    
    DZCLabStatus status = [self statusForSection:sourceIndexPath.section];
    NSMutableArray *labs = (NSMutableArray *)(self.labsByStatus[@(status)]);

    NSUInteger sourceRow = (NSUInteger) sourceIndexPath.row;
    NSUInteger destRow = (NSUInteger) destinationIndexPath.row;

    DZCLab *lab = labs[sourceRow];
    [labs removeObjectAtIndex:sourceRow];
    [labs insertObject:lab atIndex:destRow];
    
    [self.labOrdering removeObject:lab.humanName];
    
    if (destRow == [labs count]-1) {
        [self.labOrdering addObject:lab.humanName];
    } else {
        DZCLab *aboveLab = labs[destRow];
        NSUInteger aboveLabOrderIdx = [self.labOrdering indexOfObject:aboveLab.humanName];
        [self.labOrdering insertObject:lab.humanName atIndex:aboveLabOrderIdx];
    }
    
    [self saveSortOrder:self.labOrdering];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // ht: http://stackoverflow.com/a/850036/734716
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        NSInteger row = 0;
        if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
            row = [self tableView:tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
        }
        return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];     
    }
    
    return proposedDestinationIndexPath;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    DZCLabStatus status = [self.statusForTableViewSection[(NSUInteger)section] intValue];
    return DZCLabsTableViewSectionTitles[status];
}

#pragma mark - UITableViewDelegate methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZCLab *lab = [self objectForRowAtIndexPath:indexPath];
    DZCLabViewController *subLabViewController = [[DZCLabViewController alloc] initWithLab:lab];
    subLabViewController.dataController = self.dataController;
    subLabViewController.padDetailNavigationController = self.padDetailNavigationController;

    UINavigationController *targetVC;
    if (self.padDetailNavigationController && lab.subLabs.count == 0) {
        targetVC = self.padDetailNavigationController;
    } else {
        targetVC = self.navigationController;
    }
    [targetVC pushViewController:subLabViewController animated:YES];
}

#pragma mark - Property overrides

- (NSMutableDictionary *)labsByStatus
{
    if(!_labsByStatus) {
        _labsByStatus = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return _labsByStatus;
}

- (NSMutableArray *)statusForTableViewSection
{
    if (!_statusForTableViewSection) {
        _statusForTableViewSection = [NSMutableArray array];
    }
    return _statusForTableViewSection;
}

- (UISegmentedControl *)filterControl {
    if (!_filterControl) {
        _filterControl = [[UISegmentedControl alloc] initWithItems:@[
                                                                     NSLocalizedString(@"All Labs", nil),
                                                                     NSLocalizedString(@"North", nil),
                                                                     NSLocalizedString(@"Central", nil)
                                                                     ]];
        _filterControl.selectedSegmentIndex = DZCLabsListFilterAll;
        self.selectedFilter = DZCLabsListFilterAll;
        [_filterControl addTarget:self action:@selector(labListFilterControlChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _filterControl;
}

@end
