#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCApiClient.h"

@interface DZCDataController ()

@property (nonatomic, strong) DZCApiClient *apiClient;
@property (nonatomic, strong) NSMutableSet *labsDownloaded;
@property (nonatomic, readonly, strong) NSSet *labs;

@end

@implementation DZCDataController

@synthesize labsDownloaded = _labsDownloaded, labs = _labs, apiClient = _apiClient;

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

- (DZCApiClient *)apiClient {
    if (!_apiClient) {
        _apiClient = [[DZCApiClient alloc] init];
    }
    return _apiClient;
}

@end
