#import <Foundation/Foundation.h>

@class DZCLab;

typedef enum {
    DZCLabStatusOpen,
    DZCLabStatusClosed,
    DZCLabStatusReserved,
    DZCLabStatusReservedSoon,
    DZCLabStatusPartiallyReserved
} DZCLabStatus;

@interface DZCDataController : NSObject

- (NSArray *)labsWithStatus:(DZCLabStatus)status;

// TODO do I need this?
//- (DZCLabStatus)statusForLab:(DZCLab *)lab;

- (NSInteger *)machinesUsedInLab:(DZCLab *)lab;

- (NSInteger *)machinesTotalInLab:(DZCLab *)lab;

@end
