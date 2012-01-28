#import "DZCLabsViewController.h"
#import "DZCTableViewCellOpenLab.h"
#import "DZCTableViewCellClosedLab.h"
#import "DZCDataController.h"

enum DZCLabsTableViewSections {
    DZCLabsTableViewSectionOpen = 0,
    DZCLabsTableViewSectionClosed,
    DZCLabsTableViewNumSections
};

static NSString *DZCLabsTableViewSectionTitles[DZCLabsTableViewNumSections];
static NSString *DZCLabsTableViewSectionCellIDs[DZCLabsTableViewNumSections];

__attribute__((constructor)) static void __InitTableViewStrings()
{
    @autoreleasepool {
        DZCLabsTableViewSectionTitles[DZCLabsTableViewSectionOpen] = NSLocalizedString(@"Open Labs", nil);
        DZCLabsTableViewSectionTitles[DZCLabsTableViewSectionClosed] = NSLocalizedString(@"Closed Labs", nil);
        
        DZCLabsTableViewSectionCellIDs[DZCLabsTableViewSectionOpen] = NSLocalizedString(@"DZCTableViewCellOpenLab", nil);
        DZCLabsTableViewSectionCellIDs[DZCLabsTableViewSectionClosed] = NSLocalizedString(@"DZCTableViewCellClosedLab", nil);
    }
}

@interface DZCLabsViewController () 

@property (nonatomic, strong) NSArray *labs;

@end


@implementation DZCLabsViewController

@synthesize dataController = _dataController, labs = _labs;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIViewController View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = NSLocalizedString(@"CAEN Labs", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return DZCLabsTableViewNumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = DZCLabsTableViewSectionCellIDs[indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = (UITableViewCell *)[nib objectAtIndex:0];
        
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        //cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    switch (indexPath.section) {
        case DZCLabsTableViewSectionOpen:
            ((DZCTableViewCellOpenLab *) cell).labNameLabel.text = [NSString stringWithFormat:@"%d.%d", indexPath.section, indexPath.row];
            break;
            
        case DZCLabsTableViewSectionClosed:
            ((DZCTableViewCellClosedLab *) cell).labNameLabel.text = [NSString stringWithFormat:@"%d.%d", indexPath.section, indexPath.row];
            break;
            
        default:
            assert(0);
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return DZCLabsTableViewSectionTitles[section];
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
}

#pragma mark - Property overrides

- (NSArray *)labs
{
    if(!_labs) {
        _labs = [NSMutableArray array];
        
        // TODO there must be a better way to build a 2D array of NSArray
        for (int i=0; i<DZCLabStatusNumStatuses; ++i) {
            [(NSMutableArray *)_labs addObject:[NSArray array]];
        }
    }
    return _labs;
}

@end
