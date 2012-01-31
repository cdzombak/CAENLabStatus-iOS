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

// TODO refactor this implementation to achieve better logic/caching and API/network separation

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
    [self.labStatusApiClient
                    getPath:@"lab-statuses.php"
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
                NSLog(@"Unknown status string '%@' for lab '%@' in building '%@'", statusString, [lab humanName], [lab building]);
                status = [[DZCLabStatusHelper statusGuessForLab:(DZCLab *)lab] intValue];
            }
            
            [labsResult setObject:[NSNumber numberWithInt:status] forKey:lab];
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
        
        [self.hostInfoApiClient
                        getPath:@"computers.json"
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
    
    // based on view-source:http://labwatch.engin.umich.edu/labs/mobile.php
    
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
                 [[DZCLab alloc] initWithBuilding:@"DC" room:@"" humanName:@"Duderstadt Center (All)"],
                 [[DZCLab alloc] initWithBuilding:@"AH" room:@"" humanName:@"Angell Hall (Fishbowl)"],
                 // [[DZCLab alloc] initWithBuilding:@"RAC" room:@"108" humanName:@"???"], // no idea where this is
                 [[DZCLab alloc] initWithBuilding:@"SEB" room:@"3010" humanName:@"School of Ed 3010"],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"2054C" humanName:@"Ugli 2054C"],
                 [[DZCLab alloc] initWithBuilding:@"SHAPIRO" room:@"B100" humanName:@"Ugli Basement"],
                 [[DZCLab alloc] initWithBuilding:@"BAITS_COMAN" room:@"" humanName:@"Baits Coman (all)"], // rooms: 2300, 1000, 1209
                 [[DZCLab alloc] initWithBuilding:@"BURSLEY" room:@"2506" humanName:@"Bursley 2506"],
                 [[DZCLab alloc] initWithBuilding:@"MO-JO" room:@"163" humanName:@"MoJo 163"],
                 nil];
    }
    return _labs;
}

@end
