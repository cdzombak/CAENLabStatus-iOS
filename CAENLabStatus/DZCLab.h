#import <Foundation/Foundation.h>

@interface DZCLab : NSObject <NSCopying>

@property (nonatomic, readonly, strong) NSString *building;
@property (nonatomic, readonly, strong) NSString *room;
@property (nonatomic, readonly, strong) NSString *humanName;

- (id)initWithBuilding:(NSString*)building room:(NSString*)room humanName:(NSString*)humanName;

- (NSComparisonResult)compareHumanName:(DZCLab *)aLab;

@end
