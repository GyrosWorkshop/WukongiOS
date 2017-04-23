//
//  Enhancement.m
//  Wukong
//
//  Created by Qusic on 4/24/17.
//  Copyright © 2017 Qusic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptainHook.h"

@interface BKSProcessAssertion : NSObject
- (instancetype)initWithPID:(int)pid flags:(unsigned)flags reason:(unsigned)reason name:(NSString *)name withHandler:(id)handler acquire:(BOOL)acquire;
@end

CHDeclareClass(BKSProcessAssertion)

CHOptimizedMethod(6, self, id, BKSProcessAssertion, initWithPID, int, pid, flags, unsigned, flags, reason, unsigned, reason, name, NSString *, name, withHandler, id, handler, acquire, BOOL, acquire) {
    if ([name isEqualToString:@"Web content visible"]) {
        if (reason == 13) {
            reason = 7;
        }
    }
    return CHSuper(6, BKSProcessAssertion, initWithPID, pid, flags, flags, reason, reason, name, name, withHandler, handler, acquire, acquire);
}

CHConstructor {
    @autoreleasepool {
        CHLoadLateClass(BKSProcessAssertion);
        CHHook(6, BKSProcessAssertion, initWithPID, flags, reason, name, withHandler, acquire);
    }
}
