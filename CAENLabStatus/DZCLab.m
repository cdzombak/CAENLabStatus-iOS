#import "DZCLab.h"

@interface DZCLab ()

@property (nonatomic, strong) NSString *building;
@property (nonatomic, strong) NSString *room;
@property (nonatomic, strong) NSString *humanName;

@end

@implementation DZCLab

@synthesize building = _building, room = _room, humanName = _humanName;

- (id)initWithBuilding:(NSString*)building
                  room:(NSString*)room
             humanName:(NSString*)humanName
{
    self = [super init];
    if (self) {    
        self.building = building;
        self.room = room;
        self.humanName = humanName;
    }
    return self;
}

/**
 * Sort labs based on human name.
 */
- (NSComparisonResult)compareHumanName:(DZCLab *)aLab
{
    return [self.humanName compare:aLab.humanName];
}

- (BOOL)isEqual:(id)object
{
    return ([self.building isEqualToString:[object building]]
            && [self.room isEqualToString:[object room]]
            && [self.humanName isEqualToString:[object humanName]]);
}

#pragma mark - NSCopying methods

- (id)copyWithZone:(NSZone *)zone
{
    DZCLab *copy = [[[self class] allocWithZone: zone] initWithBuilding:self.building room:self.room humanName:self.humanName];
    return copy;
}

@end
