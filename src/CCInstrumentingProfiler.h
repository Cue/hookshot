//
//  CCInstrumentingProfiler
//  Greplin
//
//  Created by Robby Walker on 9/10/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifdef GREPLIN_DEBUG

#define CHECKPOINT(s) [CCInstrumentingProfiler addCheckpoint:s]

#define TAG(o, s) [CCInstrumentingProfiler setTag:s forObject:o]

#define PROFILE_CPP_FUNCTION(className, name) CCStackProfiler __cc_stack_instrumenter__(className, name)

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


#else

#define CHECKPOINT(s)

#define TAG(o, s)

#define PROFILE_CPP_FUNCTION(className, name)

#endif
