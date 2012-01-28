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
@property (nonatomic, strong) NSMutableSet *labsDownloadedHostInfo;
@property (nonatomic, readonly, strong) NSSet *labs;
@property (nonatomic, strong) id labStatuses;

- (NSString *)apiIdForLab:(DZCLab *)lab;

@end

@implementation DZCDataController

@synthesize labsDownloadedHostInfo = _labsDownloadedHostInfo, labs = _labs, apiClient = _apiClient, labStatuses = _labStatuses;

/**
 * Make the data controller (re)load all lab statuses.
 * 
 * This is intended to be used when the app launches or returns to
 * foreground to ensure we show current data.
 *
 * Your block is called when the response finishes, whether or
 * not there is an error.
 */
- (void)reloadLabStatusesWithBlock:(void(^)(NSError *error))block
{
    [self.apiClient getPath:@"lab-statuses.php"
                 parameters:nil 
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        if (responseObject != nil) {
                            self.labStatuses = responseObject;
                            if (block) block(nil);
                        } else {
                            if (block) block([[NSError alloc] init]);
                        }
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (block) block(error);
                    }
     ];
}

/**
 * Gets each known lab and its status.
 */
- (void)labsWithStatus:(DZCLabStatus)status withBlock:(void(^)(NSArray *labs))block
{
    void (^labsReady)(void) = ^ {
        NSMutableArray *matchingLabs = [NSMutableArray array];
        
        for (id lab in self.labs) {
            NSString* result = [self.labStatuses objectForKey:[self apiIdForLab:lab]];
            if (result && [result isEqualToString:DZCLabStatusStrings[status]]) {
                [matchingLabs addObject:lab];
            } else if (result == nil && status == DZCLabStatusClosed) {
                // I hate the data that comes from this API
                [matchingLabs addObject:lab];
            }
        }
        
        if (block) block(matchingLabs);
    };
    
    if (self.labStatuses) {
        labsReady();
    } else {
        [self reloadLabStatusesWithBlock:^(NSError *error) {
            // TODO handle error
            if (error) assert(0);
            
            labsReady();
        }];
    }
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

#pragma mark - Private helper methods

- (NSString *)apiIdForLab:(DZCLab *)lab
{
    return [NSString stringWithFormat:@"%@%@", lab.building, lab.room];
}

@end
