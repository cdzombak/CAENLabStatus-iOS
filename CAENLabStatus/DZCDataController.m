#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCLabStatusApiClient.h"
#import "DZCHostInfoApiClient.h"
#import "DZCLabStatusHelper.h"

static NSString *DZCLabStatusStrings[DZCLabStatusCount];

__attribute__((constructor)) static void __DZCInitLabStatusStrings()
{
    @autoreleasepool {
        DZCLabStatusStrings[DZCLabStatusOpen] = @"Open";
        DZCLabStatusStrings[DZCLabStatusClosed] = @"Closed";
        DZCLabStatusStrings[DZCLabStatusClosedSoon] = @"Closed Soon";
        DZCLabStatusStrings[DZCLabStatusReserved] = @"Reserved";
        DZCLabStatusStrings[DZCLabStatusReservedSoon] = @"Reserved Soon";
        DZCLabStatusStrings[DZCLabStatusPartiallyReserved] = @"Partially Reserved";
    }
}

/* Number of times to retry failed API queries */
#define RETRIES ((NSUInteger) 3)

/* Seconds to wait between retries */
#define RETRY_DELAY_SECONDS ((NSTimeInterval) 1.0)

#pragma mark - Data Controller

@interface DZCDataController ()

@property (nonatomic, readonly, strong) DZCLabStatusApiClient *labStatusApiClient;
@property (nonatomic, readonly, strong) DZCHostInfoApiClient *hostInfoApiClient;

/* labStatuses is a dictionary that maps a lab object to an NSNumber with int DZCLabStatus.
 * It can be set to nil to clear the cache; it is recreated as an empty mutable dictionary on any access. */
@property (nonatomic, strong) NSMutableDictionary *labStatuses;

/* labHostInfo is a dictionary that maps a lab object to an array of hosts in the lab.
 * It can be set to nil to clear the cache; it is recreated as an empty mutable dictionary on any access/ */
@property (nonatomic, strong) NSMutableDictionary *labHostInfo;

@end

@implementation DZCDataController

@synthesize labStatusApiClient = _labStatusApiClient,
            hostInfoApiClient = _hostInfoApiClient,
            labs = _labs
            ;

- (void)labsAndStatusesWithBlock:(void(^)(NSDictionary *labs, NSError *error))block
{
    if ([self.labStatuses count] != 0) {
        if (block) block(self.labStatuses, nil);
    } else {
        [self reloadLabStatusesWithBlock:^(NSError* error) {
            if (error) {
                if (block) block(nil, error);
            } else {
                if (block) block(self.labStatuses, nil);
            }
        }];
    }
}

- (void)hostsInLab:(DZCLab *)lab withBlock:(void(^)(NSArray *hosts, NSError *error))block
{
    if (self.labHostInfo[lab] != nil) {
        if (block) block(self.labHostInfo[lab], nil);
    } else {
        [self reloadHostInfoForLab:lab withBlock:^(NSError *error) {
            if (error) {
                if (block) block(nil, error);
            } else {
                if (block) block(self.labHostInfo[lab], nil);
            }
        }];
    }
}

- (void)machineCountsInLab:(DZCLab *)lab withBlock:(void(^)(NSNumber *used, NSNumber *total, DZCLab *lab, NSError *error))block
{
    __block void (^hostInfoReady)(NSArray *) = ^(NSArray *hosts) {
        NSUInteger used = 0;

        for (id host in hosts) {
            NSNumber *inUse = host[@"in_use"];
            if ([inUse boolValue]) {
                used++;
            }
        }

        NSNumber *total = [lab hostCount];
        if ([hosts count] > [total unsignedIntegerValue]) total = @([hosts count]);

        if (block) block(@(used), total, lab, nil);
    };
    
    if ((self.labHostInfo)[lab]) {
        hostInfoReady(self.labHostInfo[lab]);
    } else {
        [self reloadHostInfoForLab:lab withBlock:^(NSError *error) {
            if (error) {
                if (block) block(nil, nil, lab, error);
            } else {
                hostInfoReady(self.labHostInfo[lab]);
            }
        }];
    }
}

- (void)reloadLabStatusesWithBlock:(void(^)(NSError *error))resultBlock
{
    __block NSInteger retries = RETRIES;

    // http://jeremywsherman.com/blog/2013/02/27/leak-free-recursive-blocks/
    void (^__block __weak weakRetryResultBlock)(id, NSError *);
    void (^retryResultBlock)(id, NSError *);
    weakRetryResultBlock = retryResultBlock = ^(id response, NSError* error) {
        if (response && !error) {
            [self setLabsFromApiResponse:response];
            if (resultBlock) resultBlock(nil);
            return;
        }

        if (retries > 0) {
            NSLog(@"Retrying lab status query...");
            retries--;

            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RETRY_DELAY_SECONDS*NSEC_PER_SEC));
            dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                [self makeLabStatusApiRequestWithBlock:weakRetryResultBlock];
            });
        } else {
            if (!error) error = [[NSError alloc] init];
            if (resultBlock) resultBlock(error);
        }
    };

    [self makeLabStatusApiRequestWithBlock:retryResultBlock];
}

- (void)makeLabStatusApiRequestWithBlock:(void(^)(id response, NSError *error))resultBlock
{
    [self.labStatusApiClient getPath:@"lab-statuses.php"
                          parameters:nil
                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                 if (responseObject != nil) {
                                     if (resultBlock) resultBlock(responseObject, nil);
                                 } else {
                                     if (resultBlock) resultBlock(responseObject, [[NSError alloc] init]);
                                 }
                             }
                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                 if (resultBlock) resultBlock(nil, error);
                             }
     ];
}

- (void)reloadHostInfoForLab:(DZCLab *)lab withBlock:(void(^)(NSError *error))block
{
    __block NSInteger retries = RETRIES;

    // http://jeremywsherman.com/blog/2013/02/27/leak-free-recursive-blocks/
    void (^__block __weak weakRetryResultBlock)(id, NSError *);
    void (^retryResultBlock)(id, NSError *);
    weakRetryResultBlock = retryResultBlock = ^(id response, NSError* error) {
        if (response && !error) {
            self.labHostInfo[lab] = response;
            if (block) block(nil);
            return;
        }

        if (retries > 0) {
            NSLog(@"Retrying host info query...");
            retries--;

            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RETRY_DELAY_SECONDS*NSEC_PER_SEC));
            dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                [self makeHostInfoApiRequestForLab:lab withBlock:weakRetryResultBlock];
            });
        } else {
            if (!error) error = [[NSError alloc] init];
            if (block) block(error);
        }
    };

    [self makeHostInfoApiRequestForLab:lab withBlock:retryResultBlock];
}

- (void)makeHostInfoApiRequestForLab:(DZCLab *)lab withBlock:(void(^)(id response, NSError *error))block
{
    [self.hostInfoApiClient getPath:@"computers.json"
                         parameters:@{@"building": lab.building, @"room": lab.room}
                            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                if (responseObject != nil) {
                                    if (block) block(responseObject, nil);
                                } else {
                                    if (block) block(nil, [[NSError alloc] init]);
                                }
                            }
                            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                if (block) block(nil, error);
                            }
     ];
}

- (void)clearCache
{
    self.labHostInfo = nil;
    self.labStatuses = nil;
}

#pragma mark - Private helper methods

- (NSString *)apiIdForLab:(DZCLab *)lab
{
    return [NSString stringWithFormat:@"%@%@", lab.building, lab.room];
}

- (void)setLabsFromApiResponse:(id)response
{
    self.labStatuses = nil;
    
    for (DZCLab* lab in self.labs) {
        NSString* statusString = response[[self apiIdForLab:lab]];
        DZCLabStatus status;
        
        if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusOpen]]) {
            status = DZCLabStatusOpen;
        } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusReserved]]) {
            status = DZCLabStatusReserved;
        } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusReservedSoon]]) {
            status = DZCLabStatusReservedSoon;
        } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusPartiallyReserved]]) {
            status = DZCLabStatusPartiallyReserved;
        } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusClosed]]) {
            status = DZCLabStatusClosed;
        } else if ([statusString isEqualToString:DZCLabStatusStrings[DZCLabStatusClosedSoon]]) {
            status = DZCLabStatusClosedSoon;
        } else {
            // nil, empty, or unrecognized string means the lab is either closed or not present but open
            // defer to another, date/time processing controller
//            NSLog(@"fyi: unknown status string '%@' for lab '%@' in building '%@'", statusString, [lab humanName], [lab building]);
            status = [[DZCLabStatusHelper statusGuessForLab:(DZCLab *)lab] intValue];
        }
        
        (self.labStatuses)[lab] = @(status);
    }
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

- (NSMutableDictionary *)labStatuses
{
    if (!_labStatuses) {
        _labStatuses = [NSMutableDictionary dictionary];
    }
    return _labStatuses;
}

- (NSSet *)labs
{
    // I have to do this because the way the API is designed requires prior knowledge of all the labs
    // for various reasons: to determine whether one is closed, weed out duplicates (!), get accurate counts, etc.
    
    // based on view-source:http://labwatch.engin.umich.edu/labs/mobile.php
    // and http://www.engin.umich.edu/caen/computers/search/alllabs.html

    // in event of a conflict between those two canonical data sources, http://labwatch.engin.umich.edu/labs/mobile.php wins
    // because it is my goal to emulate that page

    // I hate everything.

    // now, there certainly are better ways to ship a dataset with an app.
    // but I didn't know that when I wrote this, and at least it's a pretty small dataset.
    
    if (!_labs) {
        _labs = [NSSet setWithObjects:
                 [[DZCLab alloc] initWithBuilding:@"BEYSTER" room:@"1695" humanName:@"Beyster (CSE) 1695" hostCount:@49 latitude:@(42.292832) longitude:@(-83.716285) subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"BEYSTER" room:@"1620" humanName:@"Beyster (CSE) 1620" hostCount:@43 latitude:@(42.292832) longitude:@(-83.716285) subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"1230" humanName:@"EECS 1230" hostCount:@28 latitude:@(42.292499) longitude:@(-83.714354) subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"2331" humanName:@"EECS 2331" hostCount:@19 latitude:@(42.292499) longitude:@(-83.714354) subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"4440" humanName:@"EECS 4440" hostCount:@22 latitude:@(42.292499) longitude:@(-83.714354) subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2304" humanName:@"GGBL 2304" hostCount:@19 latitude:@42.293155 longitude:@-83.713780 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2505" humanName:@"GGBL 2505" hostCount:@30 latitude:@42.293155 longitude:@-83.713780 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"IOE" room:@"G610" humanName:@"IOE G610" hostCount:@25 latitude:@42.291031 longitude:@-83.713782 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"CHRY" room:@"273" humanName:@"Chrysler 273" hostCount:@15 latitude:@42.290806 longitude:@-83.716727 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"COOLEY" room:@"1934" humanName:@"Cooley 1934" hostCount:@12 latitude:@42.290632 longitude:@-83.713662 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"FXB" room:@"B085" humanName:@"FXB B085" hostCount:@24 latitude:@42.293616 longitude:@-83.712031 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"LBME" room:@"1310" humanName:@"LBME 1310" hostCount:@25 latitude:@42.288784 longitude:@-83.713713 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"GFL" room:@"224" humanName:@"GFL/EPB 224" hostCount:@44 latitude:@42.293332 longitude:@-83.710813 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"NAME" room:@"134" humanName:@"NAME 134" hostCount:@20 latitude:@42.293107 longitude:@-83.709312 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SRB" room:@"2230" humanName:@"SRB 2230" hostCount:@27 latitude:@42.29440 longitude:@-83.71161 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"AH" room:@"" humanName:@"Angell Hall (Fishbowl)" hostCount:@20 latitude:@42.27680 longitude:@-83.73960 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"RAC" room:@"108" humanName:@"Ross Academic Ctr 108" hostCount:@3 latitude:@42.268650 longitude:@-83.740980 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SEB" room:@"3010" humanName:@"School of Ed 3010" hostCount:@10 latitude:@42.273985 longitude:@-83.736401 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"2054C" humanName:@"Ugli 2054C" hostCount:@10 latitude:@42.275769 longitude:@-83.737182 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"B100" humanName:@"Ugli Basement" hostCount:@24 latitude:@42.275769 longitude:@-83.737182 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"BURSLEY" room:@"2506" humanName:@"Bursley 2506" hostCount:@8 latitude:@(42.293673) longitude:@(-83.719965) subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"MO-JO" room:@"163" humanName:@"MoJo 163" hostCount:@3 latitude:@42.280077 longitude:@-83.731522 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"" humanName:@"Pierpont (all)" hostCount:@74 latitude:@(42.291350) longitude:@(-83.717417)
                                          subLabs:[NSSet setWithObjects:
                                                   [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B505" humanName:@"Pierpont B505" hostCount:@26 latitude:@(42.291350) longitude:@(-83.717417) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B507" humanName:@"Pierpont B507" hostCount:@26 latitude:@(42.291350) longitude:@(-83.717417) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B521" humanName:@"Pierpont B521" hostCount:@22 latitude:@(42.291350) longitude:@(-83.717417) subLabs:nil],
                                                   nil]
                  ],
                 [[DZCLab alloc] initWithBuilding:@"BAITS_COMAN" room:@"1000" humanName:@"Baits II 1000" hostCount:@2 latitude:@(42.293788) longitude:@(-83.723267) subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"" humanName:@"Duderstadt Ctr (all)" hostCount:@345 latitude:@(42.29114) longitude:@(-83.71577)
                                          subLabs:[NSSet setWithObjects:
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"2E" humanName:@"2nd Floor East" hostCount:@12 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"2S" humanName:@"2nd Floor South" hostCount:@20 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"2SW" humanName:@"2nd Floor SW" hostCount:@29 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3E" humanName:@"3rd Floor East" hostCount:@25 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3EA" humanName:@"3rd Floor East Alcove" hostCount:@22 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3NE" humanName:@"3rd Floor NE" hostCount:@90 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3S" humanName:@"3rd Floor South" hostCount:@16 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3SW" humanName:@"3rd Floor SW" hostCount:@80 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3WA" humanName:@"3rd Floor West Alcove" hostCount:@25 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"LLE" humanName:@"Lower Level East" hostCount:@12 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"LLC" humanName:@"Lower Level Center" hostCount:@12 latitude:@(42.29114) longitude:@(-83.71577) subLabs:nil],
                                                   nil]
                  ],
                 nil];
    }
    return _labs;
}

@end
