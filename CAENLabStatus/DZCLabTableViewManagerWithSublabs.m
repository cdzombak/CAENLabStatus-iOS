#import "DZCLabTableViewManagerWithSublabs.h"
#import "DZCLab.h"
#import "DZCDataController.h"

@interface DZCLabTableViewManagerWithSublabs ()

@property (nonatomic, strong) NSArray *sortedSubLabs;

@end

@implementation DZCLabTableViewManagerWithSublabs

- (void)configureTableView:(UITableView *)tableView
{
    [super configureTableView:tableView];

    tableView.allowsSelection = NO;
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
    return self.sortedSubLabs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath.section == 0);

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    DZCLab *lab = self.sortedSubLabs[indexPath.row];

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
    
    return cell;
}

@end
