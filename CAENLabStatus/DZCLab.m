#import "DZCLab.h"

@interface DZCLab ()

@property (nonatomic, copy) NSString *building;
@property (nonatomic, copy) NSString *room;
@property (nonatomic, copy) NSString *humanName;
@property (nonatomic, copy) NSNumber *hostCount;

@end

@implementation DZCLab

@synthesize building = _building, room = _room, humanName = _humanName, hostCount = _hostCount;

- (id)initWithBuilding:(NSString*)building
                  room:(NSString*)room
             humanName:(NSString*)humanName
            hostCount:(NSNumber *)hostCount
{
    self = [super init];
    if (self) {    
        self.building = building;
        self.room = room;
        self.humanName = humanName;
        self.hostCount = hostCount;
    }
    return self;
}

- (void)dealloc
{
    [_building release];
    [_room release];
    [_humanName release];
    [_hostCount release];
    
    [super dealloc];
}

/**
 * Sort labs based on human name.
 */
- (NSComparisonResult)compareHumanName:(DZCLab *)aLab
{
    return [self.humanName compare:aLab.humanName];
}

#pragma mark - NSCopying methods

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

@end
