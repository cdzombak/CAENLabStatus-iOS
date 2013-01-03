#import <Foundation/Foundation.h>

@interface DZCLab : NSObject <NSCopying>

@property (nonatomic, readonly, copy) NSString *building;
@property (nonatomic, readonly, copy) NSString *room;
@property (nonatomic, readonly, copy) NSString *humanName;
@property (nonatomic, readonly, copy) NSNumber *hostCount;
@property (nonatomic, readonly, copy) NSSet    *subLabs;
@property (nonatomic, readonly, copy) NSNumber *latitude;
@property (nonatomic, readonly, copy) NSNumber *longitude;

- (id)initWithBuilding:(NSString*)building room:(NSString*)room humanName:(NSString*)humanName hostCount:(NSNumber *)hostCount subLabs:(NSSet *)subLabs DEPRECATED_ATTRIBUTE;

- (id)initWithBuilding:(NSString*)building
                  room:(NSString*)room
             humanName:(NSString*)humanName
             hostCount:(NSNumber *)hostCount
              latitude:(NSNumber *)latitude
             longitude:(NSNumber *)longitude
               subLabs:(NSSet *)subLabs;

- (NSComparisonResult)compareHumanName:(DZCLab *)aLab;

@end
