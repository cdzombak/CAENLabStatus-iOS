#import <Foundation/Foundation.h>

@class DZCLab;

typedef NS_ENUM(NSInteger, DZCLabStatus) {
    DZCLabStatusOpen = 0,
    DZCLabStatusReservedSoon,
    DZCLabStatusPartiallyReserved,
    DZCLabStatusReserved,
    DZCLabStatusClosedSoon,
    DZCLabStatusClosed,
    DZCLabStatusCount
};

@interface DZCDataController : NSObject

@property (nonatomic, readonly, strong) NSSet *labs;

/**
 * Gets each known lab and its status, loading data from the network into
 * the cache if necessary.
 * 
 * Calls your block with a dictionary with key `DZCLab`, object `NSNumber`
 * with `int DZCLabStatus`.
 *
 * The `error` paramater to the block is nil if there was no error.
 */ 
- (void)labsAndStatusesWithBlock:(void(^)(NSDictionary *labs, NSError *error))block;

/**
 * Gets statistics about computer usage in the given lab, loading data
 * from the network into the cache if necessary.
 *
 * Calls your block with the statistics once any network activity is complete.
 * `error` will be nil if these was no error.
 */
- (void)machineCountsInLab:(DZCLab *)lab withBlock:(void(^)(NSNumber *used, NSNumber *total, DZCLab *lab, NSError *error))block;

/**
 * Get info about the hosts in the given lab.
 *
 * Calls your block with an array of dictionaries once any network activity is complete.
 * `error` will be nil if these was no error.
 */
- (void)hostsInLab:(DZCLab *)lab withBlock:(void(^)(NSArray *hosts, NSError *error))block;

/**
 * Make the data controller (re)load and cache all lab statuses.
 * 
 * This is intended to be used when the app launches or returns to
 * foreground to ensure we show current data.
 *
 * Your block is called when the lab statuses are ready. `error`
 * is nil if there was no error.
 */
- (void)reloadLabStatusesWithBlock:(void(^)(NSError *error))block;

/**
 * Make the data controller (re)load and cache host info for the given lab.
 * 
 * Your block is called when the host info is ready. `error`
 * is nil if there was no error.
 */
- (void)reloadHostInfoForLab:(DZCLab *)lab withBlock:(void(^)(NSError *error))block;

/**
 * Clears the cache. This affects lab status and host info.
 */
- (void)clearCache;

/**
 * Fetch the map image cached for the given building, if it exists.
 * Returns a map image or NULL.
 */
- (UIImage *)cachedMapImageForBuilding:(NSString *)building;

/**
 * Caches the given image as the map image for the given building.
 */
- (void)cacheMapImage:(UIImage *)image forBuilding:(NSString *)building;


@end
