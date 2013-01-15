//
//  CCReflection
//  Greplin
//
//  Created by Robby Walker on 9/8/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//

#import <objc/runtime.h>

#ifdef __cplusplus
extern "C" {
#endif

Method GetSuperMethod(Class cls, SEL selector);

BOOL HasOwnMethod(Class cls, SEL sel);

BOOL HasOwnClassMethod(Class cls, SEL sel);

void MethodSwizzle(Class cls, SEL a, SEL b);

void ClassMethodSwizzle(Class cls, SEL a, SEL b);

void MethodCopy(Class cls, SEL definition, SEL destination);

void ClassMethodCopy(Class cls, SEL definition, SEL destination);

#ifdef __cplusplus
}
#endif
