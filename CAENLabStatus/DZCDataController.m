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
#define RETRIES ((NSUInteger)2)

/* Seconds to wait between retries */
#define RETRY_DELAY_SECONDS ((double) 1.0)

#pragma mark Network Activity Indicator

@interface UIApplication(NetworkActivityIndicator)

- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

@end

@implementation UIApplication (NetworkActivityIndicator)

static int networkActivityCount = 0;

- (void)showNetworkActivityIndicator
{      
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(showNetworkActivityIndicator) withObject:nil waitUntilDone:NO];     
    }
    
    if (!networkActivityCount) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    
    networkActivityCount++;
}

- (void)hideNetworkActivityIndicator {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(hideNetworkActivityIndicator) withObject:nil waitUntilDone:NO];     
    }
    
    networkActivityCount = MAX(networkActivityCount - 1, 0);
    if (!networkActivityCount) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

@end

#pragma mark - Data Controller

@interface DZCDataController ()

@property (nonatomic, readonly, strong) DZCLabStatusApiClient *labStatusApiClient;
@property (nonatomic, readonly, strong) DZCHostInfoApiClient *hostInfoApiClient;
@property (nonatomic, readonly, strong) NSSet *labs;

/* labStatuses is a dictionary that maps a lab object to an NSNumber with int DZCLabStatus.
 * It can be set to nil to clear the cache; it is recreated as an empty mutable dictionary on any access. */
@property (nonatomic, strong) NSMutableDictionary *labStatuses;

/* labHostInfo is a dictionary that maps a lab object to an array of hosts in the lab.
 * It can be set to nil to clear the cache; it is recreated as an empty mutable dictionary on any access/ */
@property (nonatomic, strong) NSMutableDictionary *labHostInfo;

- (void)setLabsFromApiResponse:(id)response;
- (NSString *)apiIdForLab:(DZCLab *)lab;

@end

@implementation DZCDataController

@synthesize labHostInfo = _labHostInfo, labs = _labs, labStatusApiClient = _labStatusApiClient, hostInfoApiClient = _hostInfoApiClient, labStatuses = _labStatuses;

- (void)labsAndStatusesWithBlock:(void(^)(NSDictionary *labs, NSError *error))block
{
    void (^labsReady)(NSDictionary*) = ^(NSDictionary* labStatuses) {
        if (block) block(labStatuses, nil);
    };
    
    if ([self.labStatuses count] != 0) {
        labsReady(self.labStatuses);
    } else {
        __block NSUInteger retries = RETRIES;
        
        __block void (^reloadLabStatusResultBlock)(NSError *) = [^(NSError* error) {
            if (error && retries > 0) {
                NSLog(@"Retrying lab status query...");
                retries--;

                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, RETRY_DELAY_SECONDS*NSEC_PER_SEC);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                    [self reloadLabStatusesWithBlock:reloadLabStatusResultBlock];
                } );
            } else if (error) {
                if (block) block(nil, error);
            } else {
                labsReady(self.labStatuses);
            }
        } copy];
        
        [self reloadLabStatusesWithBlock:reloadLabStatusResultBlock];
    }
}

- (void)machineCountsInLab:(DZCLab *)lab withBlock:(void(^)(NSNumber *used, NSNumber *total, DZCLab *lab, NSError *error))block
{
    void (^hostInfoReady)(NSArray *) = ^(NSArray *hosts) {
        NSUInteger used = 0;
        
        for (id host in hosts) {
            NSNumber *inUse = [host objectForKey:@"in_use"];
            if ([inUse boolValue] == YES) {
                used++;
            }
        }
        
        NSNumber *total = [lab hostCount];
        if ([hosts count] > [total intValue]) total = [NSNumber numberWithInt:[hosts count]];
        
        if (block) block([NSNumber numberWithInt:used], total, lab, nil);
    };
    
    if ([self.labHostInfo objectForKey:lab]) {
        hostInfoReady([self.labHostInfo objectForKey:lab]);
    } else {
        __block NSUInteger retries = RETRIES;
        
        __block void (^reloadHostInfoResultBlock)(NSError *) = [^(NSError* error) {
            if (error && retries > 0) {
                NSLog(@"Retrying host info query...");
                retries--;

                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, RETRY_DELAY_SECONDS*NSEC_PER_SEC);
                dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                    [self reloadHostInfoForLab:lab withBlock:reloadHostInfoResultBlock];
                } );
            } else if (error) {
                if (block) block(nil, nil, lab, error);
            } else {
                hostInfoReady([self.labHostInfo objectForKey:lab]);
            }
        } copy];
        
        [self reloadHostInfoForLab:lab withBlock:reloadHostInfoResultBlock];
    }
}

- (void)reloadLabStatusesWithBlock:(void(^)(NSError *error))block
{
    NSLog(@"Kicking off lab status request...");
    [[UIApplication sharedApplication] showNetworkActivityIndicator];

    [self.labStatusApiClient getPath:@"lab-statuses.php"
                          parameters:nil
                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                 if (responseObject != nil) {
                                     [self setLabsFromApiResponse:responseObject];
                                     if (block) block(nil);
                                 } else {
                                     if (block) block([[NSError alloc] init]);
                                 }
                                 
                                 [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                             }
                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                 if (block) block(error);
                                 
                                 [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                             }
    ];
}

- (void)reloadHostInfoForLab:(DZCLab *)lab withBlock:(void(^)(NSError *error))block
{
    NSLog(@"Kicking off host info request for %@...", [self apiIdForLab:lab]);
    [[UIApplication sharedApplication] showNetworkActivityIndicator];
    
    [self.hostInfoApiClient getPath:@"computers.json"
                         parameters:@{@"building": lab.building, @"room": lab.room}
                            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                if (responseObject != nil) {
                                    [self.labHostInfo setObject:responseObject forKey:lab];
                                    if (block) block(nil);
                                } else {
                                    if (block) block([[NSError alloc] init]);
                                }
                                
                                [[UIApplication sharedApplication] hideNetworkActivityIndicator];
                            }
                            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                if (block) block(error);
                                
                                [[UIApplication sharedApplication] hideNetworkActivityIndicator];
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
        NSString* statusString = [response objectForKey:[self apiIdForLab:lab]];
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
            NSLog(@"fyi: unknown status string '%@' for lab '%@' in building '%@'", statusString, [lab humanName], [lab building]);
            status = [[DZCLabStatusHelper statusGuessForLab:(DZCLab *)lab] intValue];
        }
        
        [self.labStatuses setObject:@(status) forKey:lab];
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
    
    if (!_labs) {
        _labs = [NSSet setWithObjects:
                 [[DZCLab alloc] initWithBuilding:@"BEYSTER" room:@"1695" humanName:@"Beyster (CSE) 1695" hostCount:@49 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"BEYSTER" room:@"1620" humanName:@"Beyster (CSE) 1620" hostCount:@43 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"1230" humanName:@"EECS 1230" hostCount:@28 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"2331" humanName:@"EECS 2331" hostCount:@19 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"4440" humanName:@"EECS 4440" hostCount:@22 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2304" humanName:@"GGBL 2304" hostCount:@19 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2505" humanName:@"GGBL 2505" hostCount:@30 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"IOE" room:@"G610" humanName:@"IOE G610" hostCount:@25 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"CHRY" room:@"273" humanName:@"Chrysler 273" hostCount:@15 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"COOLEY" room:@"1934" humanName:@"Cooley 1934" hostCount:@12 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"FXB" room:@"B085" humanName:@"FXB B085" hostCount:@24 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"LBME" room:@"1310" humanName:@"LBME 1310" hostCount:@25 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"GFL" room:@"224" humanName:@"GFL/EPB 224" hostCount:@44 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"NAME" room:@"134" humanName:@"NAME 134" hostCount:@20 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SRB" room:@"2230" humanName:@"SRB 2230" hostCount:@27 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"AH" room:@"" humanName:@"Angell Hall (Fishbowl)" hostCount:@20 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"RAC" room:@"108" humanName:@"Ross Academic Ctr 108" hostCount:@3 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SEB" room:@"3010" humanName:@"School of Ed 3010" hostCount:@10 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"2054C" humanName:@"Ugli 2054C" hostCount:@10 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"B100" humanName:@"Ugli Basement" hostCount:@24 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"BURSLEY" room:@"2506" humanName:@"Bursley 2506" hostCount:@8 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"MO-JO" room:@"163" humanName:@"MoJo 163" hostCount:@3 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"" humanName:@"Pierpont (all)" hostCount:@74
                                          subLabs:[NSSet setWithObjects:
                                                   [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B505" humanName:@"Pierpont B505" hostCount:@26 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B507" humanName:@"Pierpont B507" hostCount:@26 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B521" humanName:@"Pierpont B521" hostCount:@22 subLabs:nil],
                                                   nil]
                  ],
                 [[DZCLab alloc] initWithBuilding:@"BAITS_COMAN" room:@"1000" humanName:@"Baits II 1000" hostCount:@2 subLabs:nil],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"" humanName:@"Duderstadt Ctr (all)" hostCount:@345
                                          subLabs:[NSSet setWithObjects:
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"2E" humanName:@"2nd Floor East" hostCount:@12 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"2S" humanName:@"2nd Floor South" hostCount:@20 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"2SW" humanName:@"2nd Floor SW" hostCount:@29 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3E" humanName:@"3rd Floor East" hostCount:@25 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3EA" humanName:@"3rd Floor East Alcove" hostCount:@22 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3NE" humanName:@"3rd Floor NE" hostCount:@90 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3S" humanName:@"3rd Floor South" hostCount:@16 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3SW" humanName:@"3rd Floor SW" hostCount:@80 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"3WA" humanName:@"3rd Floor West Alcove" hostCount:@25 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"LLE" humanName:@"Lower Level East" hostCount:@12 subLabs:nil],
                                                   [[DZCLab alloc] initWithBuilding:@"DC" room:@"LLC" humanName:@"Lower Level Center" hostCount:@12 subLabs:nil],
                                                   nil]
                  ],
                 nil];
    }
    return _labs;
}

@end
