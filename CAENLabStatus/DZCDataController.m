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
@property (nonatomic, readonly, strong) NSArray *labs;
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
    NSLog(@"Kicking off lab status request...");
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
 * 
 * Returns a dictionary with key DZCLab, object DZCLabStatus.
 */
- (void)labsAndStatusesWithBlock:(void(^)(NSDictionary *labs, NSError *error))block
{
    void (^labsReady)(void) = ^ {
        NSMutableDictionary *labsResult = [NSMutableDictionary dictionary];
        
        for (id lab in self.labs) {
            NSString* statusString = [self.labStatuses objectForKey:[self apiIdForLab:lab]];
            NSNumber* status = nil;
            
            if (statusString == nil) {
                // I hate this API. this means it is either closed or not present but open
                status = [NSNumber numberWithInt:DZCLabStatusClosed];
            } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusOpen]]) {
                status = [NSNumber numberWithInt:DZCLabStatusOpen];
            } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusReserved]]) {
                status = [NSNumber numberWithInt:DZCLabStatusReserved];
            } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusReservedSoon]]) {
                status = [NSNumber numberWithInt:DZCLabStatusReservedSoon];
            } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusPartiallyReserved]]) {
                status = [NSNumber numberWithInt:DZCLabStatusPartiallyReserved];
            }
            
            [labsResult setObject:status forKey:lab];
        }
        
        if (block) block(labsResult, nil);
    };
    
    if (self.labStatuses) {
        labsReady();
    } else {
        [self reloadLabStatusesWithBlock:^(NSError *error) {
            if (error) assert(0); // TODO handle error
            labsReady();
        }];
    }
}

#pragma mark - Private helper methods

- (NSString *)apiIdForLab:(DZCLab *)lab
{
    return [NSString stringWithFormat:@"%@%@", lab.building, lab.room];
}

#pragma mark - Property Overrides

- (DZCApiClient *)apiClient {
    if (!_apiClient) {
        _apiClient = [[DZCApiClient alloc] init];
    }
    return _apiClient;
}

- (NSArray *)labs
{
    // TODO there must be a better way to get this initial dataset into the codebase

    // I have to do this because the way the API is designed requires prior knowledge of all the labs
    // for various reasons: to determine whether one is closed, to weed out duplicates (!), etc.
    
    if (!_labs) {
        _labs = [NSArray arrayWithObjects:
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B505" humanName:@"Pierpont B505"],
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B507" humanName:@"Pierpont B507"],
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B521" humanName:@"Pierpont B521"],
                 [[DZCLab alloc] initWithBuilding:@"CSE" room:@"1695" humanName:@"CSE 1695"],
                 [[DZCLab alloc] initWithBuilding:@"CSE" room:@"1620" humanName:@"CSE 1620"],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"1230" humanName:@"EECS 1230"],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"2331" humanName:@"EECS 2331"],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"4440" humanName:@"EECS 4440"],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2304" humanName:@"GGBL 2304"],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2505" humanName:@"GGBL 2505"],
                 [[DZCLab alloc] initWithBuilding:@"IOE" room:@"G610" humanName:@"IOE G610"],
                 [[DZCLab alloc] initWithBuilding:@"COOLEY" room:@"1934" humanName:@"Cooley 1934"],
                 [[DZCLab alloc] initWithBuilding:@"FXB" room:@"B085" humanName:@"FXB B085"],
                 [[DZCLab alloc] initWithBuilding:@"LBME" room:@"1310" humanName:@"LBME 1310"],
                 [[DZCLab alloc] initWithBuilding:@"GFL" room:@"224" humanName:@"GFL/EPB 224"],
                 [[DZCLab alloc] initWithBuilding:@"NAME" room:@"134" humanName:@"NAME 134"],
                 [[DZCLab alloc] initWithBuilding:@"SRB" room:@"2230" humanName:@"SRB 2230"],
                 nil];
    }
    return _labs;
}

@end
