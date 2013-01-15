//
//  CCInstanceMessageInstrumentation
//  Greplin
//
//  Created by Robby Walker on 9/10/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>


#ifdef HOOKSHOT_ENABLED

@interface CCInstanceMessageInstrumentation : NSObject

+ (void)preventInstrumentation:(Class)cls selector:(SEL)selector;

+ (void)instrumentInstanceMessages:(Class)cls
                            before:(void(^)(id, Class, SEL))before
                             after:(void(^)(id, Class, SEL))after
                            except:(NSArray *)exceptions;

@end

#endif
