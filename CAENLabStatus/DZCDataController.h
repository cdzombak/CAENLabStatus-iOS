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

- (void)labsAndStatusesWithBlock:(void(^)(NSArray *labs))block;

// TODO do I need this?
//- (DZCLabStatus)statusForLab:(DZCLab *)lab;

//- (NSInteger *)machinesUsedInLab:(DZCLab *)lab;

//- (NSInteger *)machinesTotalInLab:(DZCLab *)lab;

@end
