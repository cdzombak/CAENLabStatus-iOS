#import <Foundation/Foundation.h>

@class DZCLab;

typedef enum {
    DZCLabStatusOpen,
    DZCLabStatusClosed,
    DZCLabStatusReserved,
    DZCLabStatusReservedSoon,
    DZCLabStatusPartiallyReserved,
    DZCLabStatusNumStatuses
} DZCLabStatus;

@interface DZCDataController : NSObject

- (void)reloadLabStatusesWithBlock:(void(^)(NSError *error))block;

- (void)labsAndStatusesWithBlock:(void(^)(NSDictionary *labs, NSError *error))block;

- (void)machineCountsInLab:(DZCLab *)lab withBlock:(void(^)(NSNumber *used, NSNumber *total, DZCLab *lab, NSError *error))block;

@end
