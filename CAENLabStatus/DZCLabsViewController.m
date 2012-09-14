#import "DZCLabsViewController.h"
#import "DZCTableViewCellOpenLab.h"
#import "DZCTableViewCellClosedLab.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCAboutViewController.h"
#import "DZCSubLabsViewController.h"
#import "UIColor+DZCColors.h"

#import <QuartzCore/QuartzCore.h>

static NSString *DZCLabsTableViewSectionTitles[DZCLabStatusCount];
static NSString *DZCLabsTableViewSectionCellIDs[DZCLabStatusCount];

__attribute__((constructor)) static void __InitTableViewStrings()
{
    @autoreleasepool {
        DZCLabsTableViewSectionTitles[DZCLabStatusOpen] = NSLocalizedString(@"Open", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusClosed] = NSLocalizedString(@"Closed", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusReservedSoon] = NSLocalizedString(@"Reserved Soon", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusPartiallyReserved] = NSLocalizedString(@"Partially Reserved", nil);
        DZCLabsTableViewSectionTitles[DZCLabStatusReserved] = NSLocalizedString(@"Reserved", nil);
        
        DZCLabsTableViewSectionCellIDs[DZCLabStatusOpen] = NSLocalizedString(@"DZCTableViewCellOpenLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabStatusReservedSoon] = NSLocalizedString(@"DZCTableViewCellOpenLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabStatusPartiallyReserved] = NSLocalizedString(@"DZCTableViewCellOpenLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabStatusReserved] = NSLocalizedString(@"DZCTableViewCellClosedLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabStatusClosed] = NSLocalizedString(@"DZCTableViewCellClosedLab", nil);
    }
}

static NSString *DZCLabsViewControllerSortOrderPrefsKey = @"DZCLabsViewControllerSortOrder";

@interface DZCLabsViewController () 

@property (nonatomic, strong) NSMutableArray *labOrdering;
@property (nonatomic, strong) NSMutableDictionary *labsByStatus;
@property (nonatomic, strong) NSMutableArray *statusForTableViewSection;

- (void)loadData;
- (DZCLabStatus) statusForSection:(NSInteger)section;

- (BOOL)saveSortOrder:(NSMutableArray *)sortOrder;
- (NSMutableArray *)retrieveSavedSortOrder;

@end


@implementation DZCLabsViewController

@synthesize dataController = _dataController, labsByStatus = _labsByStatus, statusForTableViewSection = _statusForTableViewSection, labOrdering = _labOrdering;

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
       
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"247-InfoCircle"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(pressedAboutButton:)];
    
    self.navigationItem.leftBarButtonItem = aboutButton;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.allowsSelection = YES;
    self.tableView.allowsMultipleSelection = NO;
    
    self.labOrdering = [self retrieveSavedSortOrder];

    self.navigationController.navigationBar.tintColor = [UIColor dzc_logoBlueColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = NSLocalizedString(@"CAEN Labs", nil);
    
    [self loadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeMotionShake) {
        [self refreshData];
    }
    
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)]) {
        [super motionEnded:motion withEvent:event];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Buttons

- (void)pressedAboutButton:(id)sender
{
    DZCAboutViewController *aboutViewController = [[DZCAboutViewController alloc] initWithNibName:@"DZCAboutViewController" bundle:nil];
    aboutViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    aboutViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    
    [self.navigationController presentViewController:aboutViewController animated:YES completion:nil];
}

#pragma mark - Data Management

- (void)refreshData
{
    self.labsByStatus = nil;
    [self.dataController clearCache];
    [self loadData];
}

- (void)loadData
{
    [self startLoading];
    
    [self.dataController labsAndStatusesWithBlock:^(NSDictionary *labsResult, NSError *error) {
        
        [self stopLoading];
        
        self.labsByStatus = nil;
        
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Retrieving Data", nil)
                                                            message:NSLocalizedString(@"Please ensure you have a network connection. If you do, the CAEN lab info service might be down.\n\nTry refreshing again.", nil)
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        NSArray* sortedLabs = nil;
        if (!self.labOrdering) {
            sortedLabs = [[labsResult allKeys] sortedArrayUsingSelector:@selector(compareHumanName:)];
            
            self.labOrdering = [NSMutableArray array];
            
            for (id lab in sortedLabs) {
                [self.labOrdering addObject:[lab humanName]];
            }
            
            [self saveSortOrder:self.labOrdering];
        } else {
            sortedLabs = [[labsResult allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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
        
        self.statusForTableViewSection = nil;
        
        for (id lab in sortedLabs) {
            DZCLabStatus status = [(NSNumber *)[labsResult objectForKey:lab] intValue];
            
            NSMutableArray *labs = [self.labsByStatus objectForKey:[NSNumber numberWithInt:status]];
            if (!labs) {
                [self.labsByStatus setObject:[NSMutableArray array] forKey:[NSNumber numberWithInt:status]];
                labs = [self.labsByStatus objectForKey:[NSNumber numberWithInt:status]];
            }
            
            [labs addObject:lab];
        }
        
        for (DZCLabStatus i=0; i<DZCLabStatusCount; ++i) {
            if ([self.labsByStatus objectForKey:[NSNumber numberWithInt:i]] != nil) {
                [self.statusForTableViewSection addObject:[NSNumber numberWithInt:i]];
            }
        }
        
        [self.tableView reloadData];
    }];
}

#pragma mark - Private methods

- (DZCLabStatus) statusForSection:(NSInteger)section
{
    return [[self.statusForTableViewSection objectAtIndex:section] intValue];
}

- (BOOL)saveSortOrder:(NSMutableArray *)sortOrder
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (!standardUserDefaults) {
        return NO;
    }
    
	[standardUserDefaults setObject:sortOrder forKey:DZCLabsViewControllerSortOrderPrefsKey];
	[standardUserDefaults synchronize];
    
    return YES;
}

- (NSMutableArray *)retrieveSavedSortOrder
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if (!standardUserDefaults) {
        return nil;
    }
    
    NSArray *resultArray = [standardUserDefaults arrayForKey:DZCLabsViewControllerSortOrderPrefsKey];
    if (resultArray == nil) {
        return nil;
    }
    
    return [NSMutableArray arrayWithArray:resultArray];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.statusForTableViewSection count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)[self.labsByStatus objectForKey:[NSNumber numberWithInt:[self statusForSection:section]]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZCLabStatus status = [self statusForSection:indexPath.section];
    
    NSString *cellIdentifier = DZCLabsTableViewSectionCellIDs[status];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = (UITableViewCell *)[nib objectAtIndex:0];
    }
    
    if ([[self.labsByStatus objectForKey:[NSNumber numberWithInt:status]] count] < indexPath.row+1) {
        return cell;
    }
    
    DZCLab *lab = [(NSArray *)[self.labsByStatus objectForKey:[NSNumber numberWithInt:status]] objectAtIndex:indexPath.row];
    
    switch (status) {
        case DZCLabStatusOpen:
        case DZCLabStatusPartiallyReserved:
        case DZCLabStatusReservedSoon: {
            ((DZCTableViewCellOpenLab *) cell).labNameLabel.text = lab.humanName;
            
            [self.dataController machineCountsInLab:lab withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {
                if (error) {
                    ((DZCTableViewCellOpenLab *) cell).labOpenCountLabel.text = @"...";
                    ((DZCTableViewCellOpenLab *) cell).labTotalCountLabel.text = @"...";
                    return;
                }

                ((DZCTableViewCellOpenLab *) cell).labOpenCountLabel.text = [NSString stringWithFormat:@"%d", [total intValue]-[used intValue]];
                ((DZCTableViewCellOpenLab *) cell).labTotalCountLabel.text = [NSString stringWithFormat:@"%d", [total intValue]];
                
                if ([used floatValue]/[total floatValue] >= 0.9) {
                    ((DZCTableViewCellOpenLab *) cell).labNameLabel.font = [UIFont systemFontOfSize:20.0];
                    ((DZCTableViewCellOpenLab *) cell).labOpenCountLabel.font = [UIFont systemFontOfSize:20.0];
                } else {
                    ((DZCTableViewCellOpenLab *) cell).labNameLabel.font = [UIFont boldSystemFontOfSize:20.0];
                    ((DZCTableViewCellOpenLab *) cell).labOpenCountLabel.font = [UIFont boldSystemFontOfSize:20.0];
                }
            }];
            break;
        }
            
        case DZCLabStatusClosed:
        case DZCLabStatusReserved: {
            ((DZCTableViewCellClosedLab *) cell).labNameLabel.text = lab.humanName;
            
            [self.dataController machineCountsInLab:lab withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {
                if (error) {
                    ((DZCTableViewCellClosedLab *) cell).labCountLabel.text = @"...";
                    return;
                }
                
                ((DZCTableViewCellClosedLab *) cell).labCountLabel.text = [NSString stringWithFormat:@"%d", [total intValue]];
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
    
    if (status == DZCLabStatusOpen && lab.subLabs != nil && [lab.subLabs count] > 0) {
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        //cell.userInteractionEnabled = YES;
    } else {
        //cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        //cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (DZCLabStatusOpen == [self statusForSection:indexPath.section]);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (sourceIndexPath.section != destinationIndexPath.section) {
        NSLog(@"WARNING: it appears a move to another section succeeded somehow");
    }
    
    DZCLabStatus status = [self statusForSection:sourceIndexPath.section];
    NSMutableArray *labs = (NSMutableArray *)[self.labsByStatus objectForKey:[NSNumber numberWithInt:status]];

    DZCLab *lab = [labs objectAtIndex:sourceIndexPath.row];
    [labs removeObjectAtIndex:sourceIndexPath.row];
    [labs insertObject:lab atIndex:destinationIndexPath.row];
    
    [self.labOrdering removeObject:lab.humanName];
    
    if (destinationIndexPath.row == [labs count]-1) {
        [self.labOrdering addObject:lab.humanName];
    } else {
        DZCLab *aboveLab = [labs objectAtIndex:destinationIndexPath.row+1];
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
    DZCLabStatus status = [[self.statusForTableViewSection objectAtIndex:section] intValue];
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
    NSLog(@"pressed %d.%d", indexPath.section, indexPath.row);
    
    DZCLab *lab = [(NSArray *)[self.labsByStatus objectForKey:[NSNumber numberWithInt:[self statusForSection:indexPath.section]]] objectAtIndex:indexPath.row];
    if (lab.subLabs == nil || [lab.subLabs count] == 0) {
        return;
    }
    
    DZCSubLabsViewController *subLabViewController = [[DZCSubLabsViewController alloc] initWithLab:lab];
    subLabViewController.dataController = self.dataController;
    
    [self.navigationController pushViewController:subLabViewController animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DZCLab *lab = [(NSArray *)[self.labsByStatus objectForKey:[NSNumber numberWithInt:[self statusForSection:indexPath.section]]] objectAtIndex:indexPath.row];
    
    if (lab.subLabs == nil || [lab.subLabs count] == 0) {
        return nil;
    }
    
    return indexPath;
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

    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0.0, 0.0, headerView.frame.size.width, 1.0);
    topBorder.backgroundColor = [UIColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:0.8].CGColor;
    [headerView.layer addSublayer:topBorder];

    CALayer *secondaryTopBorder = [CALayer layer];
    secondaryTopBorder.frame = CGRectMake(0.0, 1.0, headerView.frame.size.width, 1.0);
    secondaryTopBorder.backgroundColor = [UIColor colorWithRed:80.0/255.0 green:80.0/255.0 blue:140.0/255.0 alpha:0.6].CGColor;
    [headerView.layer addSublayer:secondaryTopBorder];

    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0, headerView.frame.size.height, headerView.frame.size.width, 1.0);
    bottomBorder.backgroundColor = [UIColor colorWithRed:25.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:0.9].CGColor;
    [headerView.layer addSublayer:bottomBorder];

    return headerView;
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

@end
