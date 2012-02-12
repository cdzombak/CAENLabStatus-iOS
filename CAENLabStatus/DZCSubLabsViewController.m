#import "DZCSubLabsViewController.h"

#import "DZCTableViewCellOpenLab.h"
#import "DZCDataController.h"
#import "DZCLab.h"

@interface DZCSubLabsViewController ()

@property (nonatomic, strong) NSMutableArray *labs;

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

    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelection = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = self.lab.humanName;
    
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
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

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
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DZCTableViewCellOpenLab" owner:self options:nil];
        cell = (UITableViewCell *)[nib objectAtIndex:0];
    }
    
    if ([self.labs count] < indexPath.row+1) {
        return cell;
    }
    
    DZCLab *lab = [self.labs objectAtIndex:indexPath.row];
    
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
