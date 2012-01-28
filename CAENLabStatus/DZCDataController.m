#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCApiClient.h"

static NSString *DZCLabStatusStrings[DZCLabStatusNumStatuses];

__attribute__((constructor)) static void __InitStatusStrings()
{
    @autoreleasepool {
        DZCLabStatusStrings[DZCLabStatusOpen] = @"Open";
        DZCLabStatusStrings[DZCLabStatusClosed] = @"Closed";
        DZCLabStatusStrings[DZCLabStatusReserved] = @"Reserved";
        DZCLabStatusStrings[DZCLabStatusReservedSoon] = @"Reserved Soon";
        DZCLabStatusStrings[DZCLabStatusPartiallyReserved] = @"Partially Reserved";
    }
}

@interface DZCDataController ()

@property (nonatomic, strong) DZCApiClient *apiClient;
@property (nonatomic, strong) NSMutableSet *labsDownloaded;
@property (nonatomic, readonly, strong) NSSet *labs;
@property (nonatomic, strong) id labStatuses;

@end

@implementation DZCDataController

@synthesize labsDownloaded = _labsDownloaded, labs = _labs, apiClient = _apiClient, labStatuses = _labStatuses;

- (void)reloadLabStatuses
{
    [self.apiClient getPath:@"lab-statuses.php"
                 parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (responseObject != nil) {
                         self.labStatuses = responseObject;
                     }
                 }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"error");
                    }];
}

- (void)labsWithStatus:(DZCLabStatus)status withBlock:(void(^)(NSArray *))block
{
    
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
