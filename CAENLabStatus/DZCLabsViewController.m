#import "DZCLabsViewController.h"
#import "DZCTableViewCellOpenLab.h"
#import "DZCTableViewCellClosedLab.h"
#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCAboutViewController.h"

enum DZCLabsTableViewSections {
    DZCLabsTableViewSectionOpen = 0,
    DZCLabsTableViewSectionReservedSoon,
    DZCLabsTableViewSectionPartiallyReserved,
    DZCLabsTableViewSectionReserved,
    DZCLabsTableViewSectionClosed,
    DZCLabsTableViewNumSections
};

static NSString *DZCLabsTableViewSectionTitles[DZCLabsTableViewNumSections];
static NSString *DZCLabsTableViewSectionCellIDs[DZCLabsTableViewNumSections];

__attribute__((constructor)) static void __InitTableViewStrings()
{
    @autoreleasepool {
        DZCLabsTableViewSectionTitles[DZCLabsTableViewSectionOpen] = NSLocalizedString(@"Open", nil);
        DZCLabsTableViewSectionTitles[DZCLabsTableViewSectionClosed] = NSLocalizedString(@"Closed", nil);
        DZCLabsTableViewSectionTitles[DZCLabsTableViewSectionReservedSoon] = NSLocalizedString(@"Reserved Soon", nil);
        DZCLabsTableViewSectionTitles[DZCLabsTableViewSectionPartiallyReserved] = NSLocalizedString(@"Partially Reserved", nil);
        DZCLabsTableViewSectionTitles[DZCLabsTableViewSectionReserved] = NSLocalizedString(@"Reserved", nil);
        
        DZCLabsTableViewSectionCellIDs[DZCLabsTableViewSectionOpen] = NSLocalizedString(@"DZCTableViewCellOpenLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabsTableViewSectionReservedSoon] = NSLocalizedString(@"DZCTableViewCellOpenLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabsTableViewSectionPartiallyReserved] = NSLocalizedString(@"DZCTableViewCellOpenLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabsTableViewSectionReserved] = NSLocalizedString(@"DZCTableViewCellClosedLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabsTableViewSectionClosed] = NSLocalizedString(@"DZCTableViewCellClosedLab", nil);
    }
}

@interface DZCLabsViewController () 

@property (nonatomic, strong) NSArray *labs;

- (void)loadData;
- (void)refreshData;

@end


@implementation DZCLabsViewController

@synthesize dataController = _dataController, labs = _labs;

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
    return DZCLabsTableViewNumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)[self.labs objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = DZCLabsTableViewSectionCellIDs[indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = (UITableViewCell *)[nib objectAtIndex:0];
    }
    
    if ([[self.labs objectAtIndex:indexPath.section] count] < indexPath.row+1) {
        return cell;
    }
    
    DZCLab *lab = [(NSArray *)[self.labs objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    switch (indexPath.section) {
        case DZCLabsTableViewSectionOpen:
        case DZCLabsTableViewSectionPartiallyReserved:
        case DZCLabsTableViewSectionReservedSoon: {
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
            
        case DZCLabsTableViewSectionClosed:
        case DZCLabsTableViewSectionReserved: {
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
            NSLog(@"Unknown section encountered: %d", indexPath.section);
            assert(0);
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return DZCLabsTableViewSectionTitles[section];
}

#pragma mark - Private methods

- (void)refreshData
{
    self.labs = nil;
    [self.dataController clearCache];
    [self loadData];
}

- (void)loadData
{
    [self.dataController labsAndStatusesWithBlock:^(NSDictionary *labs, NSError *error) {
        
        self.labs = nil;
        
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Retrieving Data", nil)
                                                            message:NSLocalizedString(@"Please ensure you have a network connection. If you do, the CAEN lab info service might be down.\n\nShake the device to try refreshing the app.", nil)
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        // map statuses to sections for display
        // TODO this mapping can be made cleaner
        
        NSArray* sortedKeys = [[labs allKeys] sortedArrayUsingSelector:@selector(compareHumanName:)];
        
        for (id lab in sortedKeys) {
            DZCLabStatus status = [(NSNumber *)[labs objectForKey:lab] intValue];
            
            switch(status) {
                case DZCLabStatusOpen:
                    [(NSMutableArray *)[self.labs objectAtIndex:DZCLabsTableViewSectionOpen] addObject:lab];
                    break;
                case DZCLabStatusClosed:
                    [(NSMutableArray *)[self.labs objectAtIndex:DZCLabsTableViewSectionClosed] addObject:lab];
                    break;
                case DZCLabStatusPartiallyReserved:
                    [(NSMutableArray *)[self.labs objectAtIndex:DZCLabsTableViewSectionPartiallyReserved] addObject:lab];
                    break;
                case DZCLabStatusReserved:
                    [(NSMutableArray *)[self.labs objectAtIndex:DZCLabsTableViewSectionReserved] addObject:lab];
                    break;
                case DZCLabStatusReservedSoon:
                    [(NSMutableArray *)[self.labs objectAtIndex:DZCLabsTableViewSectionReservedSoon] addObject:lab];
                    break;
                default:
                    NSLog(@"Unknown status encountered: %d", status);
            }
        }
        
        [self.tableView reloadData];
    }];
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

- (NSArray *)labs
{
    if(!_labs) {
        _labs = [NSMutableArray array];
        
        // TODO there must be a better way to build a 2D NSArray
        for (int i=0; i<DZCLabsTableViewNumSections; ++i) {
            [(NSMutableArray *)_labs addObject:[NSMutableArray array]];
        }
    }
    return _labs;
}

@end
