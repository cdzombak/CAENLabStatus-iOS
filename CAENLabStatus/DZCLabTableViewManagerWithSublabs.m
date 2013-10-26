#import "DZCLabTableViewManagerWithSublabs.h"
#import "DZCLab.h"
#import "DZCDataController.h"
#import "DZCLabViewController.h"

@interface DZCLabTableViewManagerWithSublabs ()

@property (nonatomic, strong) NSArray *sortedSubLabs;

@end

@implementation DZCLabTableViewManagerWithSublabs

- (void)configureTableView:(UITableView *)tableView
{
    [super configureTableView:tableView];

    tableView.allowsSelection = YES;
    tableView.allowsMultipleSelection = NO;
    tableView.rowHeight = 55.0;
}

- (void)prepareData
{
    self.sortedSubLabs = [self.lab.subLabs sortedArrayUsingDescriptors:@[
                          [NSSortDescriptor sortDescriptorWithKey:@"humanName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]
                          ]];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSParameterAssert(section == 0);
    return (NSInteger) self.sortedSubLabs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath.section == 0);

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    DZCLab *lab = self.sortedSubLabs[(NSUInteger) indexPath.row];

    cell.textLabel.text = lab.humanName;
    cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];

    cell.detailTextLabel.text = @"...";
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];

    [self.dataController machineCountsInLab:lab withBlock:^(NSNumber *used, NSNumber *total, DZCLab *l, NSError *error) {
        if (error) {
            cell.detailTextLabel.text = @"...";
            return;
        }

        NSInteger freeCount = [total intValue] - [used intValue];
        float usedPercent = [used floatValue] / [total floatValue];
        float freePercent = 1.0f - usedPercent;

        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d (%d%%) free", freeCount, (int)roundf(freePercent*100)];

        if (usedPercent >= 0.8) {
            cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:17.0];
        } else {
            cell.textLabel.font = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];
            cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:17.0];
        }
    }];
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath.section == 0);

    DZCLab *lab = self.sortedSubLabs[(NSUInteger)indexPath.row];
    DZCLabViewController *labVC = [[DZCLabViewController alloc] initWithLab:lab];
    labVC.dataController = self.dataController;

    if (self.vcPushBlock) self.vcPushBlock(labVC);
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
}

@end
