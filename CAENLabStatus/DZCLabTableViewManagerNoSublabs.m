#import "DZCLabTableViewManagerNoSublabs.h"

#import "DZCDataController.h"
#import "DZCLab.h"

typedef NS_ENUM(NSInteger, DZCNoSublabsTableViewSections) {
    DZCNoSublabsTableViewSectionUsage = 0,
    DZCNoSublabsTableViewSectionFeatures,
    DZCNoSublabsTableViewSectionHosts,
    DZCNoSublabsTableViewSumSections
};

@interface DZCLabTableViewManagerNoSublabs ()

@property (nonatomic, readonly, strong) UITableViewCell *usageCell;
@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, strong) NSArray *hosts;
@property (nonatomic, strong) NSArray *featureStrings;

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
        self.hosts = [hosts sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *hostname1 = obj1[@"hostname"];
            NSString *hostname2 = obj2[@"hostname"];
            return [hostname1 localizedCaseInsensitiveCompare:hostname2];
        }];
        [self.tableView reloadData];
    }];

    NSMutableArray *featureStrings = [NSMutableArray array];
    if (self.lab.isReservable) [featureStrings addObject:NSLocalizedString(@"Reservable", nil)];
    if (self.lab.hasColorPrinting) [featureStrings addObject:NSLocalizedString(@"Color Printing", nil)];
    if (self.lab.hasScanningCopying) [featureStrings addObject:NSLocalizedString(@"Scanning/Copying", nil)];
    self.featureStrings = featureStrings;
}

#pragma mark - UITableViewDataSource methods

- (BOOL)hasHostsSection {
    return self.hosts.count != 0;
}

- (BOOL)hasFeaturesSection {
    return self.featureStrings.count != 0;
}

- (DZCNoSublabsTableViewSections)UISectionAdjustedForMissingSections:(NSInteger)section {
    if (![self hasFeaturesSection] && section >= DZCNoSublabsTableViewSectionFeatures) section++;
    if (![self hasHostsSection] && section >= DZCNoSublabsTableViewSectionHosts) section++;
    return section;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = DZCNoSublabsTableViewSumSections;
    if (![self hasFeaturesSection]) sections--;
    if (![self hasHostsSection]) sections--;
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DZCNoSublabsTableViewSections adjustedSection = [self UISectionAdjustedForMissingSections:section];

    switch(adjustedSection) {
        case DZCNoSublabsTableViewSectionUsage:
            return 1;
        case DZCNoSublabsTableViewSectionFeatures:
            return (NSInteger) self.featureStrings.count;
        case DZCNoSublabsTableViewSectionHosts:
            return (NSInteger) self.hosts.count;
        default:
            [NSException raise:@"DZCInvalidSectionException" format:@"Invalid section %d for lab table view", (int)section];
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZCNoSublabsTableViewSections adjustedSection = [self UISectionAdjustedForMissingSections:indexPath.section];

    if (adjustedSection == DZCNoSublabsTableViewSectionUsage) {
        return self.usageCell;
    }

    if (adjustedSection == DZCNoSublabsTableViewSectionFeatures) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FeatureCell"];
        cell.textLabel.text = self.featureStrings[(NSUInteger)indexPath.row];
        return cell;
    }

    NSParameterAssert(adjustedSection == DZCNoSublabsTableViewSectionHosts);

    static NSString *HostCellIdentifier = @"HostCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HostCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:HostCellIdentifier];
    }

    id host = self.hosts[(NSUInteger)indexPath.row];
    cell.textLabel.text = host[@"hostname"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ / %@ / %@", host[@"vendor"], host[@"ip"], host[@"model"]];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    DZCNoSublabsTableViewSections adjustedSection = [self UISectionAdjustedForMissingSections:section];

    switch (adjustedSection) {
        case DZCNoSublabsTableViewSectionHosts:
            return NSLocalizedString(@"Hosts", nil);
        case DZCNoSublabsTableViewSectionFeatures:
            return NSLocalizedString(@"Features", nil);
        case DZCNoSublabsTableViewSectionUsage:
            return NSLocalizedString(@"Usage", nil);
        default:
            return nil;
    }
}

#pragma mark - Property overrides

- (UITableViewCell *)usageCell
{
    if (!_usageCell) {
        _usageCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UsageCell"];

        CDZWeakSelf wSelf = self;
        [self.dataController machineCountsInLab:self.lab
                                      withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {

                                          CDZStrongSelf sSelf = wSelf;
                                          if (!sSelf) return;

                                          if (error) {
                                              sSelf->_usageCell.textLabel.text = @"…";
                                              sSelf->_usageCell.detailTextLabel.text = nil;
                                              return;
                                          }

                                          NSInteger freeCount = [total intValue] - [used intValue];
                                          float usedPercent = [used floatValue] / [total floatValue];
                                          float freePercent = 1.0f - usedPercent;
                                          
                                          sSelf->_usageCell.textLabel.text = [NSString stringWithFormat:@"%d%% free", (int)roundf(freePercent*100)];
                                          sSelf->_usageCell.detailTextLabel.text = [NSString stringWithFormat:@"%d of %d computers free", (int)freeCount, [total intValue]];
                                      }];
    }
    return _usageCell;
}

@end
