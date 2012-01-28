#import "DZCDataController.h"
#import "DZCLab.h"

@interface DZCDataController ()

@property (nonatomic, strong) NSMutableSet *labsDownloaded;
@property (nonatomic, readonly, strong) NSSet *labs;

@end

@implementation DZCDataController

@synthesize labsDownloaded = _labsDownloaded, labs = _labs;

- (NSArray *)labsWithStatus:(DZCLabStatus)status
{
#warning TODO
    
}

- (NSInteger *)machinesUsedInLab:(DZCLab *)lab
{
#warning TODO
    
}

- (NSInteger *)machinesTotalInLab:(DZCLab *)lab
{
#warning TODO
    
}

#pragma mark - Property Overrides

- (NSSet *)labs
{
    // TODO there must be a better way to get an initial dataset into the codebase
    if (!_labs) {
        _labs = [NSSet setWithObjects:
                [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B507" humanName:@"Pierpont B507"],
                nil];
    }
    return _labs;
}

@end
