//
//  CCCountInstances
//  Greplin
//
//  Created by Robby Walker on 9/7/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifdef HOOKSHOT_ENABLED

@interface CCCountInstances : NSObject

+ (void)countInstances:(Class)cls;

+ (int)getCountForTesting:(Class)cls;

@end

#endif
