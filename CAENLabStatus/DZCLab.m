#import "DZCLab.h"

@interface DZCLab ()

@property (nonatomic, readwrite, copy) NSString *building;
@property (nonatomic, readwrite, copy) NSString *room;
@property (nonatomic, readwrite, copy) NSString *humanName;
@property (nonatomic, readwrite, copy) NSNumber *hostCount;
@property (nonatomic, readwrite, copy) NSSet    *subLabs;
@property (nonatomic, readwrite, copy) NSNumber *latitude;
@property (nonatomic, readwrite, copy) NSNumber *longitude;
@property (nonatomic, readwrite, assign, getter=isReservable) BOOL reservable;
@property (nonatomic, readwrite, assign) BOOL hasColorPrinting;
@property (nonatomic, readwrite, assign) BOOL hasScanningCopying;

@end

@implementation DZCLab

- (id)initWithBuilding:(NSString*)building
                  room:(NSString*)room
             humanName:(NSString*)humanName
             hostCount:(NSNumber *)hostCount
              latitude:(NSNumber *)latitude
             longitude:(NSNumber *)longitude
            reservable:(BOOL)reservable
      hasColorPrinting:(BOOL)hasColorPrinting
    hasScanningCopying:(BOOL)hasScanningCopying
               subLabs:(NSSet *)subLabs
{
    self = [super init];
    if (self) {
        self.building = building;
        self.room = room;
        self.humanName = humanName;
        self.hostCount = hostCount;
        self.subLabs = subLabs;
        self.latitude = latitude;
        self.longitude = longitude;
        self.reservable = reservable;
        self.hasColorPrinting = hasColorPrinting;
        self.hasScanningCopying = hasScanningCopying;
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
    [_latitude release];
    [_longitude release];
    
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

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[DZCLab class]]) return NO;
    return [self isEqualToLab:(DZCLab *)object];
}

- (BOOL)isEqualToLab:(DZCLab *)lab {
    return [self.building isEqualToString:lab.building]
        && [self.room isEqualToString:lab.room]
        && [self.humanName isEqualToString:lab.humanName]
        && [self.hostCount isEqualToNumber:lab.hostCount]
        && [self.subLabs isEqualToSet:lab.subLabs]
        && [self.latitude isEqualToNumber:lab.latitude]
        && [self.longitude isEqualToNumber:lab.longitude]
        && self.isReservable == lab.isReservable
        && self.hasScanningCopying == lab.hasScanningCopying
        && self.hasColorPrinting == lab.hasColorPrinting
        ;
}

- (NSUInteger)hash {
    return [self.building hash]
        ^ [self.room hash]
        ^ [self.humanName hash]
        ^ [self.hostCount hash]
        ^ [self.subLabs hash]
        ^ [self.latitude hash]
        ^ [self.longitude hash]
        ^ (NSUInteger)(self.isReservable << 2)
        ^ (NSUInteger)(self.hasColorPrinting << 4)
        ^ (NSUInteger)(self.hasScanningCopying << 6)
        ;
}

#pragma mark - MKAnnotation methods

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [self.latitude doubleValue];
    coordinate.longitude = [self.longitude doubleValue];
    return coordinate;
}

@end
