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

//- (NSInteger *)machinesUsedInLab:(DZCLab *)lab;

//- (NSInteger *)machinesTotalInLab:(DZCLab *)lab;

@end
