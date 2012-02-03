#import <Foundation/Foundation.h>

@interface DZCLab : NSObject <NSCopying>

@property (nonatomic, readonly, copy) NSString *building;
@property (nonatomic, readonly, copy) NSString *room;
@property (nonatomic, readonly, copy) NSString *humanName;
@property (nonatomic, readonly, copy) NSNumber *hostCount;

- (id)initWithBuilding:(NSString*)building room:(NSString*)room humanName:(NSString*)humanName hostCount:(NSNumber *)hostCount;

- (NSComparisonResult)compareHumanName:(DZCLab *)aLab;

@end
