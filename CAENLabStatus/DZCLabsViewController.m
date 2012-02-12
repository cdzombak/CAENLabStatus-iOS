#import "DZCLabsViewController.h"
#import "DZCTableViewCellOpenLab.h"
#import "DZCTableViewCellClosedLab.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCAboutViewController.h"

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

@interface DZCLabsViewController () 

@property (nonatomic, strong) NSMutableDictionary *labsByStatus;
@property (nonatomic, strong) NSMutableArray *statusForTableViewSection;

- (void)loadData;
- (DZCLabStatus) statusForSection:(NSInteger)section;

@end


@implementation DZCLabsViewController

@synthesize dataController = _dataController, labsByStatus = _labsByStatus, statusForTableViewSection = _statusForTableViewSection;

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
       
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"247-InfoCircle"] style:UIBarButtonItemStylePlain target:self action:@selector(pressedAboutButton:)];
    
    self.navigationItem.leftBarButtonItem = aboutButton;
    
    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelection = NO;
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
    UIViewController *aboutNavController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    
    [self.navigationController presentModalViewController:aboutNavController animated:YES];
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
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    DZCLabStatus status = [[self.statusForTableViewSection objectAtIndex:section] intValue];
    return DZCLabsTableViewSectionTitles[status];
}

#pragma mark - Data Management

- (void)refreshData
{
    self.labsByStatus = nil;
    self.statusForTableViewSection = nil;
    [self.dataController clearCache];
    [self loadData];
}

#pragma mark - Private methods

- (void)loadData
{
    [self.dataController labsAndStatusesWithBlock:^(NSDictionary *labsResult, NSError *error) {
        
        self.labsByStatus = nil;
        self.statusForTableViewSection = nil;
        
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Retrieving Data", nil)
                                                            message:NSLocalizedString(@"Please ensure you have a network connection. If you do, the CAEN lab info service might be down.\n\nShake the device to try refreshing the app.", nil)
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        NSArray* sortedLabs = [[labsResult allKeys] sortedArrayUsingSelector:@selector(compareHumanName:)];
        
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

- (DZCLabStatus) statusForSection:(NSInteger)section
{
    return [[self.statusForTableViewSection objectAtIndex:section] intValue];
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    NSLog(@"pressed %d.%d", indexPath.section, indexPath.row);
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
