#import "DZCDataController.h"
#import "DZCLab.h"
#import "DZCLabStatusApiClient.h"
#import "DZCHostInfoApiClient.h"
#import "DZCLabStatusHelper.h"

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

/* Number of times to retry failed API queries */
#define RETRIES ((NSUInteger)4)


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
                [self reloadLabStatusesWithBlock:reloadLabStatusResultBlock];
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
                [self reloadHostInfoForLab:lab withBlock:reloadHostInfoResultBlock];
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

    [self.labStatusApiClient getPath:@"lab-statuses.php"
                          parameters:nil
                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                 if (responseObject != nil) {
                                     [self setLabsFromApiResponse:responseObject];
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

- (void)reloadHostInfoForLab:(DZCLab *)lab withBlock:(void(^)(NSError *error))block
{
    NSLog(@"Kicking off host info request for %@...", [self apiIdForLab:lab]);
    
    [self.hostInfoApiClient getPath:@"computers.json"
                         parameters:[NSDictionary dictionaryWithObjectsAndKeys:lab.building, @"building", lab.room, @"room", nil]
                            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                if (responseObject != nil) {
                                    [self.labHostInfo setObject:responseObject forKey:lab];
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
    
    for (id lab in self.labs) {
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
        } else {
            // nil, empty, or unrecognized string means the lab is either closed or not present but open
            // defer to another, date/time processing controller
            NSLog(@"fyi: unknown status string '%@' for lab '%@' in building '%@'", statusString, [lab humanName], [lab building]);
            status = [[DZCLabStatusHelper statusGuessForLab:(DZCLab *)lab] intValue];
        }
        
        [self.labStatuses setObject:[NSNumber numberWithInt:status] forKey:lab];
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
    
    // I hate everything.
    
    if (!_labs) {
        _labs = [NSSet setWithObjects:
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B505" humanName:@"Pierpont B505" hostCount:[NSNumber numberWithInt:26]],
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B507" humanName:@"Pierpont B507" hostCount:[NSNumber numberWithInt:26]],
                 [[DZCLab alloc] initWithBuilding:@"PIERPONT" room:@"B521" humanName:@"Pierpont B521" hostCount:[NSNumber numberWithInt:22]],
                 [[DZCLab alloc] initWithBuilding:@"CSE" room:@"1695" humanName:@"CSE 1695" hostCount:[NSNumber numberWithInt:49]],
                 [[DZCLab alloc] initWithBuilding:@"CSE" room:@"1620" humanName:@"CSE 1620" hostCount:[NSNumber numberWithInt:43]],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"1230" humanName:@"EECS 1230" hostCount:[NSNumber numberWithInt:28]],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"2331" humanName:@"EECS 2331" hostCount:[NSNumber numberWithInt:19]],
                 [[DZCLab alloc] initWithBuilding:@"EECS" room:@"4440" humanName:@"EECS 4440" hostCount:[NSNumber numberWithInt:22]],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2304" humanName:@"GGBL 2304" hostCount:[NSNumber numberWithInt:19]],
                 [[DZCLab alloc] initWithBuilding:@"GGBL" room:@"2505" humanName:@"GGBL 2505" hostCount:[NSNumber numberWithInt:30]],
                 [[DZCLab alloc] initWithBuilding:@"IOE" room:@"G610" humanName:@"IOE G610" hostCount:[NSNumber numberWithInt:25]],
                 [[DZCLab alloc] initWithBuilding:@"COOLEY" room:@"1934" humanName:@"Cooley 1934" hostCount:[NSNumber numberWithInt:12]],
                 [[DZCLab alloc] initWithBuilding:@"FXB" room:@"B085" humanName:@"FXB B085" hostCount:[NSNumber numberWithInt:24]],
                 [[DZCLab alloc] initWithBuilding:@"LBME" room:@"1310" humanName:@"LBME 1310" hostCount:[NSNumber numberWithInt:25]],
                 [[DZCLab alloc] initWithBuilding:@"GFL" room:@"224" humanName:@"GFL/EPB 224" hostCount:[NSNumber numberWithInt:44]],
                 [[DZCLab alloc] initWithBuilding:@"NAME" room:@"134" humanName:@"NAME 134" hostCount:[NSNumber numberWithInt:20]],
                 [[DZCLab alloc] initWithBuilding:@"SRB" room:@"2230" humanName:@"SRB 2230" hostCount:[NSNumber numberWithInt:27]],
                 /*[[DZCLab alloc] initWithBuilding:@"DC" room:@"2E" humanName:@"Duderstadt 2E"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"2S" humanName:@"Duderstadt 2S"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"2SW" humanName:@"Duderstadt 2SW"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"3E" humanName:@"Duderstadt 3E"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"3EA" humanName:@"Duderstadt 3EA"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"3NE" humanName:@"Duderstadt 3NE"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"3S" humanName:@"Duderstadt 3S"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"3SW" humanName:@"Duderstadt 3SW"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"3WA" humanName:@"Duderstadt 3W"],
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"LLE" humanName:@"Duderstadt LLE"],
                  [[DZCLab alloc] initWithBuilding:@"DC" room:@"LLC" humanName:@"Duderstadt LLC"],*/
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"" humanName:@"Duderstadt Center (All)" hostCount:[NSNumber numberWithInt:345]],
                 [[DZCLab alloc] initWithBuilding:@"AH" room:@"" humanName:@"Angell Hall (Fishbowl)" hostCount:[NSNumber numberWithInt:20]],
                 // [[DZCLab alloc] initWithBuilding:@"RAC" room:@"108" humanName:@"???"], // no idea where this is
                 [[DZCLab alloc] initWithBuilding:@"SEB" room:@"3010" humanName:@"School of Ed 3010" hostCount:[NSNumber numberWithInt:12]],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"2054C" humanName:@"Ugli 2054C" hostCount:[NSNumber numberWithInt:10]],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"B100" humanName:@"Ugli Basement" hostCount:[NSNumber numberWithInt:24]],
                 [[DZCLab alloc] initWithBuilding:@"BAITS_COMAN" room:@"" humanName:@"Baits Coman (all)" hostCount:[NSNumber numberWithInt:4]], // rooms: 2300, 1000, 1209
                 [[DZCLab alloc] initWithBuilding:@"BURSLEY" room:@"2506" humanName:@"Bursley 2506" hostCount:[NSNumber numberWithInt:8]],
                 [[DZCLab alloc] initWithBuilding:@"MO-JO" room:@"163" humanName:@"MoJo 163" hostCount:[NSNumber numberWithInt:3]],
                 nil];
    }
    return _labs;
}

@end
