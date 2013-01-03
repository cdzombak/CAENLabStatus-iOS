#import "DZCLab.h"

@interface DZCLab ()

@property (nonatomic, readwrite, copy) NSString *building;
@property (nonatomic, readwrite, copy) NSString *room;
@property (nonatomic, readwrite, copy) NSString *humanName;
@property (nonatomic, readwrite, copy) NSNumber *hostCount;
@property (nonatomic, readwrite, copy) NSSet    *subLabs;

@end

@implementation DZCLab

- (id)initWithBuilding:(NSString *)building
                  room:(NSString *)room
             humanName:(NSString *)humanName
             hostCount:(NSNumber *)hostCount
               subLabs:(NSSet *)subLabs
{
    self = [super init];
    if (self) {    
        self.building = building;
        self.room = room;
        self.humanName = humanName;
        self.hostCount = hostCount;
        self.subLabs = subLabs;
    }
    return self;
}

- (void)dealloc
{
    [_building release];
    [_room release];
    [_humanName release];
    [_hostCount release];
    [_subLabs release];
    
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
