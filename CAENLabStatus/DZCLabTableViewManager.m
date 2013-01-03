#import "DZCLabTableViewManager.h"
#import "DZCLab.h"
#import "DZCDataController.h"
#import "DZCLabTableViewManagerWithSublabs.h"

@interface DZCLabTableViewManager ()

@property (nonatomic, readwrite, strong) DZCLab *lab;
@property (nonatomic, readwrite, strong) DZCDataController *dataController;

@end

@implementation DZCLabTableViewManager

#pragma mark Class methods

+ (DZCLabTableViewManager *)tableViewManagerForLab:(DZCLab *)lab dataController:(DZCDataController *)dataController
{
    if (lab.subLabs.count != 0) {
        return [[DZCLabTableViewManagerWithSublabs alloc] initWithLab:lab dataController:dataController];
    }
    #warning TODO CDZ subclass for one lab
    return [[DZCLabTableViewManager alloc] initWithLab:lab dataController:dataController];
}

+ (UITableViewStyle)tableViewStyleForLab:(DZCLab *)lab
{
    return (lab.subLabs.count) ? UITableViewStylePlain : UITableViewStyleGrouped;
}

#pragma mark - Object lifecycle

- (id)initWithLab:(id)lab dataController:(id)dataController
{
    self = [super init];
    if (self) {
        self.lab = lab;
        self.dataController = dataController;
    }
    return self;
}

#pragma mark - UITableView Setup

- (void)configureTableView:(UITableView *)tableView
{
    tableView.delegate = self;
    tableView.dataSource = self;
}

- (void)prepareData
{
    NSAssert(NO, @"%s is an abstract method and must be overriden\n%@",
             __PRETTY_FUNCTION__,
             [NSThread callStackSymbols]);
}

@end
