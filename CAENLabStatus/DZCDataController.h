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

- (void)labsWithStatus:(DZCLabStatus)status withBlock:(void(^)(NSArray *))block;

// TODO do I need this?
//- (DZCLabStatus)statusForLab:(DZCLab *)lab;

- (NSInteger *)machinesUsedInLab:(DZCLab *)lab;

- (NSInteger *)machinesTotalInLab:(DZCLab *)lab;

- (void)reloadLabStatuses;

@end
