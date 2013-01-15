//
//  CCInstrumentingProfiler
//  Greplin
//
//  Created by Robby Walker on 9/10/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifdef HOOKSHOT_ENABLED

#ifdef __cplusplus

class CCStackProfiler {
    const char *_name;
public:
    CCStackProfiler(const char *className, const char *name);

    ~CCStackProfiler();
};
#endif


@interface CCInstrumentingProfiler : NSObject

+ (void)profileClass:(Class)cls;

+ (void)profileClass:(Class)cls except:(NSArray *)exceptions;

+ (void)addCheckpoint:(NSString *)description;

+ (void)setTag:(NSString *)tag forObject:(id)o;

@end

#endif
