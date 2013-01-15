//
//  CCReflection
//  Greplin
//
//  Created by Robby Walker on 9/8/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//

#import "CCReflection.h"


Method GetSuperMethod(Class cls, SEL selector)
{
    Method method, thisMethod = class_getClassMethod(cls, selector);
    IMP imp, thisImp = method_getImplementation(thisMethod);
    Class current = cls;
    do {
        current = class_getSuperclass(current);
        method = class_getClassMethod(current, selector);
        imp = method_getImplementation(method);
    } while (imp == thisImp);
    return method;
}


BOOL HasOwnMethod(Class cls, SEL sel)
{
    Method oldMethod = class_getInstanceMethod(cls, sel);
    Method superMethod = class_getInstanceMethod(class_getSuperclass(cls), sel);
    return oldMethod != superMethod;
}


BOOL HasOwnClassMethod(Class cls, SEL sel)
{
    Method oldMethod = class_getClassMethod(cls, sel);
    Method superMethod = class_getClassMethod(class_getSuperclass(cls), sel);
    return oldMethod != superMethod;
}


void MethodSwizzle(Class cls, SEL a, SEL b)
{
    Method oldMethod = class_getInstanceMethod(cls, a);
    Method newMethod = class_getInstanceMethod(cls, b);
    method_exchangeImplementations(oldMethod, newMethod);
}


void ClassMethodSwizzle(Class cls, SEL a, SEL b)
{
    Method oldMethod = class_getClassMethod(cls, a);
    Method newMethod = class_getClassMethod(cls, b);
    method_exchangeImplementations(oldMethod, newMethod);
}


void MethodCopy(Class cls, SEL definition, SEL destination)
{
    Method newMethod = class_getInstanceMethod(cls, definition);
    class_addMethod(cls, destination, (IMP) method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
}


void ClassMethodCopy(Class cls, SEL definition, SEL destination)
{
    Method newMethod = class_getClassMethod(cls, definition);
    Class metaClass = objc_getMetaClass(class_getName(cls));
    class_addMethod(
            metaClass, destination, (IMP) method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
}
