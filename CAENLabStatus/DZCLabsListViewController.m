#import "DZCLabsListViewController.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCAboutViewController.h"
#import "DZCLabViewController.h"
#import "ODRefreshControl.h"
#import "UIColor+DZCColors.h"

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

static NSString *DZCLabsListViewControllerSortOrderPrefsKey = @"DZCLabsViewControllerSortOrder";

static const CGFloat DZCFilterBarHeight = 43.0;

@interface DZCLabsListViewController () 

@property (nonatomic, strong) NSMutableArray *labOrdering;
@property (nonatomic, strong) NSMutableDictionary *labsByStatus;
@property (nonatomic, strong) NSMutableArray *statusForTableViewSection;

@property (nonatomic, readonly, strong) UIBarButtonItem *aboutButtonItem;
@property (nonatomic, strong) ODRefreshControl *pullRefreshControl;

@property (nonatomic, strong) UISegmentedControl *filterControl;
@property (nonatomic, assign) DZCLabsListFilter selectedFilter;

@property (nonatomic, readonly, strong) UIViewController *aboutViewController;

@end

@implementation DZCLabsListViewController

@synthesize aboutButtonItem = _aboutButtonItem,
            aboutViewController = _aboutViewController
            ;

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = NSLocalizedString(@"CAEN Labs", nil);
    }
    return self;
}

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.aboutButtonItem;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self configureFilterControl];

    self.tableView.allowsSelection = YES;
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.rowHeight = 55.0;

    self.pullRefreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
    self.pullRefreshControl.tintColor = [UIColor dzc_refreshViewColor];
    self.pullRefreshControl.backgroundColor = [UIColor dzc_refreshViewBackgroundColor];
    [self.pullRefreshControl addTarget:self action:@selector(dropViewDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    self.labOrdering = [self retrieveSavedSortOrder];

    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.tableView.contentOffset.y < DZCFilterBarHeight) {
        self.tableView.contentOffset = (CGPoint) {0.0, DZCFilterBarHeight};
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    self.filterControl.enabled = !editing;
}

- (void)configureFilterControl
{
    UISegmentedControl *filterControl = [[UISegmentedControl alloc] initWithItems:@[
                                         NSLocalizedString(@"All", nil),
                                         NSLocalizedString(@"North", nil),
                                         NSLocalizedString(@"Central", nil)
                                         ]];
    filterControl.tintColor = [UIColor colorWithRed:0.204 green:0.219 blue:0.483 alpha:1.000];
    filterControl.segmentedControlStyle = UISegmentedControlStyleBar;
    filterControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    filterControl.selectedSegmentIndex = DZCLabsListFilterAll;
    self.selectedFilter = DZCLabsListFilterAll;
    
    CGRect filterControlFrame = filterControl.frame;
    filterControlFrame.size.height = DZCFilterBarHeight - 10.0;
    filterControlFrame.origin.y = 5.0;
    filterControlFrame.size.width = self.view.bounds.size.width - 10.0;
    filterControlFrame.origin.x = 5.0;
    filterControl.frame = filterControlFrame;

    [filterControl addTarget:self
                      action:@selector(filterControlChanged:)
            forControlEvents:UIControlEventValueChanged];

    UIToolbar *filterControlContainer = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, DZCFilterBarHeight)];
    filterControlContainer.tintColor = [UIColor colorWithRed:0.204 green:0.219 blue:0.483 alpha:1.000];
    [filterControlContainer addSubview:filterControl];

    self.tableView.tableHeaderView = filterControlContainer;
    self.filterControl = filterControl;
}

#pragma mark - UI Actions

- (void)pressedAboutButton:(id)sender
{
    [self.navigationController presentViewController:self.aboutViewController animated:YES completion:nil];
}

- (void)filterControlChanged:(id)sender
{
    NSParameterAssert(sender == self.filterControl);

    self.selectedFilter = self.filterControl.selectedSegmentIndex;
    [self loadData];

    if (self.selectedFilter == DZCLabsListFilterAll) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Data Management

- (void)refreshData
{
    self.labsByStatus = nil; // TODO I think this causes some interaction which can cause a crash sometimes
    [self.dataController clearCache];
    [self loadData];
}

- (void)loadData
{
    [self.dataController labsAndStatusesWithBlock:^(NSDictionary *labsResult, NSError *error) {
        
        [self.pullRefreshControl endRefreshing];

        self.labsByStatus = nil;
        
        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Retrieving Data", nil)
                                        message:NSLocalizedString(@"Please ensure you have an Internet connection. If you do, the CAEN lab info service might be down.\n\nTry refreshing again.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@":(", nil)
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
            
            *stop = NO;
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
    return [(self.statusForTableViewSection)[section] intValue];
}

- (DZCLab *)objectForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *statusForSection = @([self statusForSection:indexPath.section]);
    return self.labsByStatus[statusForSection][indexPath.row];
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

#pragma mark - ODRefreshControl related

- (void)dropViewDidBeginRefreshing:(ODRefreshControl *)refreshControl
{
    [self refreshData];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.statusForTableViewSection count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSNumber *statusForSection = @([self statusForSection:section]);
    return [self.labsByStatus[statusForSection] count];
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
    if ([self.labsByStatus[@(status)] count] < indexPath.row+1) {
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
                float freePercent = 1.0 - usedPercent;

                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d (%d%%) free", freeCount, (int)roundf(freePercent*100)];
                
                if (usedPercent >= 0.8) {
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
            assert(0);
        }
    }
    
    if (status == DZCLabStatusOpen) {
        cell.showsReorderControl = YES;
    } else {
        cell.showsReorderControl = NO;
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

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

    DZCLab *lab = labs[sourceIndexPath.row];
    [labs removeObjectAtIndex:sourceIndexPath.row];
    [labs insertObject:lab atIndex:destinationIndexPath.row];
    
    [self.labOrdering removeObject:lab.humanName];
    
    if (destinationIndexPath.row == [labs count]-1) {
        [self.labOrdering addObject:lab.humanName];
    } else {
        DZCLab *aboveLab = labs[destinationIndexPath.row+1];
        NSInteger aboveLabOrderIdx = [self.labOrdering indexOfObject:aboveLab.humanName];
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
    DZCLabStatus status = [(self.statusForTableViewSection)[section] intValue];
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
    
    [self.navigationController pushViewController:subLabViewController animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];

    UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.opaque = NO;
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.highlightedTextColor = [UIColor whiteColor];
    headerLabel.shadowColor = [UIColor darkTextColor];
    headerLabel.shadowOffset = CGSizeMake(0.0, -1.0);

    UIFont *titleFont = [UIFont boldSystemFontOfSize:16];
    headerLabel.font = titleFont;

    CGSize textSize = [title sizeWithFont:titleFont];
    headerLabel.frame = (CGRect) { {10.0, 1.0} , textSize };

    headerLabel.text = (NSString*)title;

    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, tableView.bounds.size.width, textSize.height+2.0)];
    headerView.backgroundColor = [UIColor dzc_tableViewHeaderColor];
    [headerView addSubview:headerLabel];

    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, headerView.frame.size.width, 1.0)];
    topBorder.backgroundColor = [UIColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:0.8];
    topBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerView addSubview:topBorder];

    UIView *secondaryTopBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 1.0, headerView.frame.size.width, 1.0)];
    secondaryTopBorder.backgroundColor = [UIColor colorWithRed:80.0/255.0 green:80.0/255.0 blue:140.0/255.0 alpha:0.6];
    secondaryTopBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerView addSubview:secondaryTopBorder];

    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, headerView.frame.size.height, headerView.frame.size.width, 1.0)];
    bottomBorder.backgroundColor = [UIColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:0.9];
    bottomBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerView addSubview:bottomBorder];

    return headerView;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self adjustFilterBarVisibilityAfterScrollViewScrolled:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self adjustFilterBarVisibilityAfterScrollViewScrolled:scrollView];
}

- (void)adjustFilterBarVisibilityAfterScrollViewScrolled:(UIScrollView *)scrollView
{
    static const CGFloat DZCFilterBarMagnetismProportion = 1.6;

    // quick flick scroll up/down issue happens when you try to scroll down while
    // [scrollView setContentOffset:… animated:YES] is still happening

    if (scrollView.contentOffset.y < (DZCFilterBarHeight/DZCFilterBarMagnetismProportion)) {
        [scrollView setContentOffset:(CGPoint){0.0, 0.0} animated:YES];
    }
    else if (scrollView.contentOffset.y > (DZCFilterBarHeight/DZCFilterBarMagnetismProportion)
             && scrollView.contentOffset.y < DZCFilterBarHeight) {
        [scrollView setContentOffset:(CGPoint){0.0, DZCFilterBarHeight} animated:YES];
    }
}

#pragma mark - Property overrides

- (UIBarButtonItem *)aboutButtonItem
{
    if (!_aboutButtonItem) {
        _aboutButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"247-InfoCircle"]
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(pressedAboutButton:)];
    }
    return _aboutButtonItem;
}

- (UIViewController *)aboutViewController
{
    if (!_aboutViewController) {
        _aboutViewController = [[DZCAboutViewController alloc] initWithNibName:@"DZCAboutViewController" bundle:nil];
        _aboutViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        _aboutViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    }
    return _aboutViewController;
}

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

@end
