#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCLabStatusApiClient.h"
#import "DZCHostInfoApiClient.h"

static NSString *DZCLabStatusStrings[DZCLabStatusNumStatuses];

__attribute__((constructor)) static void __DZCInitLabStatusStrings()
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

@property (nonatomic, readonly, strong) DZCLabStatusApiClient *labStatusApiClient;
@property (nonatomic, readonly, strong) DZCHostInfoApiClient *hostInfoApiClient;
@property (nonatomic, readonly, strong) NSArray *labs;
@property (nonatomic, strong) id labStatuses;
@property (nonatomic, strong) NSMutableDictionary *labHostInfo;

- (NSString *)apiIdForLab:(DZCLab *)lab;

@end

@implementation DZCDataController

@synthesize labHostInfo = _labHostInfo, labs = _labs, labStatusApiClient = _labStatusApiClient, hostInfoApiClient = _hostInfoApiClient, labStatuses = _labStatuses;

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
    [self.labStatusApiClient getPath:@"lab-statuses.php"
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
            } else {
                NSLog(@"Unknown status string '%@'", statusString);
                status = [NSNumber numberWithInt:DZCLabStatusClosed];
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

- (void)machineCountsInLab:(DZCLab *)lab withBlock:(void(^)(NSNumber *used, NSNumber *total, DZCLab *lab, NSError *error))block
{
    void (^hostInfoReady)(void) = ^ {
        NSInteger total = 0;
        NSInteger used = 0;
        
        NSArray *hosts = [self.labHostInfo objectForKey:lab];
        for (id host in hosts) {
            total++;
            
            NSNumber *inUse = [host objectForKey:@"in_use"];
            if ([inUse boolValue] == YES) {
                used++;
            }
        }
        
        if (block) block([NSNumber numberWithInt:used], [NSNumber numberWithInt:total], lab, nil);
    };
    
    if ([self.labHostInfo objectForKey:lab]) {
        hostInfoReady();
    } else {
        NSLog(@"Kicking off host info request for %@...", [self apiIdForLab:lab]);
        
        [self.hostInfoApiClient getPath:@"computers.json"
                     parameters:[NSDictionary dictionaryWithObjectsAndKeys:lab.building, @"building", lab.room, @"room", nil]
                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            if (responseObject != nil) {
                                [self.labHostInfo setObject:responseObject forKey:lab];
                                hostInfoReady();
                            } else {
                                if (block) block(nil, nil, nil, [[NSError alloc] init]);
                            }
                        }
                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            if (block) block(nil, nil, nil, error);
                        }
         ];
    }
}

- (void)clearHostInfoCache
{
    self.labHostInfo = nil;
}

#pragma mark - Private helper methods

- (NSString *)apiIdForLab:(DZCLab *)lab
{
    return [NSString stringWithFormat:@"%@%@", lab.building, lab.room];
}

#pragma mark - Property Overrides

- (DZCLabStatusApiClient *)labStatusApiClient {
    if (!_labStatusApiClient) {
        _labStatusApiClient = [[DZCLabStatusApiClient alloc] init];
    }
    return _labStatusApiClient;
}

- (DZCHostInfoApiClient *)hostInfoApiClient {
    if (!_hostInfoApiClient) {
        _hostInfoApiClient = [[DZCHostInfoApiClient alloc] init];
    }
    return _hostInfoApiClient;
}

- (NSMutableDictionary *)labHostInfo
{
    if (!_labHostInfo) {
        _labHostInfo = [NSMutableDictionary dictionary];
    }
    return _labHostInfo;
}

- (NSArray *)labs
{
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
