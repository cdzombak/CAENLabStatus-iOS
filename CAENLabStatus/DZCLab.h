#import <Foundation/Foundation.h>

@interface DZCLab : NSObject

@property (nonatomic, readonly, strong) NSString *building;
@property (nonatomic, readonly, strong) NSString *room;
@property (nonatomic, readonly, strong) NSString *humanName;

- (id)initWithBuilding:(NSString*)building room:(NSString*)room humanName:(NSString*)humanName;

@end
