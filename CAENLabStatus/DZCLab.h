#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface DZCLab : NSObject <NSCopying, MKAnnotation>

@property (nonatomic, readonly) NSString *building;
@property (nonatomic, readonly) NSString *room;
@property (nonatomic, readonly) NSString *humanName;
@property (nonatomic, readonly) NSNumber *hostCount;
@property (nonatomic, readonly) NSSet    *subLabs;
@property (nonatomic, readonly) NSNumber *latitude;
@property (nonatomic, readonly) NSNumber *longitude;
@property (nonatomic, readonly, getter=isReservable) BOOL reservable;
@property (nonatomic, readonly) BOOL hasColorPrinting;
@property (nonatomic, readonly) BOOL hasScanningCopying;

- (id)initWithBuilding:(NSString*)building
                  room:(NSString*)room
             humanName:(NSString*)humanName
             hostCount:(NSNumber *)hostCount
              latitude:(NSNumber *)latitude
             longitude:(NSNumber *)longitude
            reservable:(BOOL)reservable
      hasColorPrinting:(BOOL)hasColorPrinting
    hasScanningCopying:(BOOL)hasScanningCopying
               subLabs:(NSSet *)subLabs;

- (NSComparisonResult)compareHumanName:(DZCLab *)aLab;

@end
