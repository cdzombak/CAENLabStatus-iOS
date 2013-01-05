#import "DZCLabTableViewManagerNoSublabs.h"
#import "DZCDataController.h"

typedef NS_ENUM(NSInteger, DZCNoSublabsTableViewSections) {
    DZCNoSublabsTableViewSectionUsage = 0,
    DZCNoSublabsTableViewSectionHosts,
    DZCNoSublabsTableViewSumSections
};

@interface DZCLabTableViewManagerNoSublabs ()

@property (nonatomic, readonly, strong) UITableViewCell *usageCell;
@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, strong) NSArray *hosts;

@end

@implementation DZCLabTableViewManagerNoSublabs

@synthesize usageCell = _usageCell;

- (void)configureTableView:(UITableView *)tableView
{
    [super configureTableView:tableView];

    tableView.allowsSelection = NO;
    tableView.allowsMultipleSelection = NO;
    tableView.rowHeight = 52;
}

- (void)prepareData
{
    [self.dataController hostsInLab:self.lab withBlock:^(NSArray *hosts, NSError *error) {
        if (error) return;
        self.hosts = hosts;
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.hosts.count) return DZCNoSublabsTableViewSumSections;
    else return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case DZCNoSublabsTableViewSectionUsage:
            return 1;
        case DZCNoSublabsTableViewSectionHosts:
            return self.hosts.count;
        default:
            [NSException raise:@"DZCInvalidSectionException" format:@"Invalid section %d for lab table view", section];
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DZCNoSublabsTableViewSectionUsage) {
        return self.usageCell;
    }

    NSParameterAssert(indexPath.section == DZCNoSublabsTableViewSectionHosts);

    static NSString *HostCellIdentifier = @"HostCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HostCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:HostCellIdentifier];
    }

    id host = self.hosts[indexPath.row];
    cell.textLabel.text = host[@"hostname"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ / %@ / %@", host[@"vendor"], host[@"ip"], host[@"model"]];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case DZCNoSublabsTableViewSectionHosts:
            return NSLocalizedString(@"Hosts", nil);
            break;
        case DZCNoSublabsTableViewSectionUsage:
            return NSLocalizedString(@"Usage", nil);
            break;
        default:
            return nil;
    }
}

#pragma mark - UITableViewDelegate methods

// n/a

#pragma mark - Property overrides

- (UITableViewCell *)usageCell
{
    if (!_usageCell) {
        _usageCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UsageCell"];

        [self.dataController machineCountsInLab:self.lab
                                      withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {
            if (error) {
                _usageCell.textLabel.text = @"…";
                _usageCell.detailTextLabel.text = nil;
                return;
            }

            NSInteger freeCount = [total intValue] - [used intValue];
            float usedPercent = [used floatValue] / [total floatValue];
            float freePercent = 1.0 - usedPercent;

            _usageCell.textLabel.text = [NSString stringWithFormat:@"%d%% free", (int)roundf(freePercent*100)];
            _usageCell.detailTextLabel.text = [NSString stringWithFormat:@"%d of %d computers free", freeCount, [total intValue]];

//            if (usedPercent >= 0.8) {
//                cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
//                cell.detailTextLabel.font = [UIFont systemFontOfSize:17.0];
//            } else {
//                cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
//                cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:17.0];
//            }
        }];
    }
    return _usageCell;
}

@end
