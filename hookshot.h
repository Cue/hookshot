//
//  hookshot.h
//  hookshot
//
//  Created by Robby Walker on 1/15/13.
//  Copyright (c) 2013 Cue. All rights reserved.
//


#ifdef HOOKSHOT_ENABLED

#import "CCInstrumentingProfiler.h"
#import "CCNativeCountInstances.h"
#import "CCInstanceMessageInstrumentation.h"
#import "CCCountInstances.h"

// Definitions for when hookshot is enabled.

#define PROFILE_CLASS(c) [CCInstrumentingProfiler profileClass:c];

#define PROFILE_CLASS_EXCEPT(c, ...) [CCInstrumentingProfiler profileClass:c except: @[ __VA_ARGS__ ]]

#define PREVENT_INSTRUMENTATION(c, s) [CCInstanceMessageInstrumentation preventInstrumentation:c selector:s]

#define CHECKPOINT(s) [CCInstrumentingProfiler addCheckpoint:s]

#define TAG(o, s) [CCInstrumentingProfiler setTag:s forObject:o]

#define PROFILE_CPP_FUNCTION(className, name) CCStackProfiler __cc_stack_instrumenter__(className, name)

#define COUNTED_CPP_CLASS(className) \
class className; \
template <> \
struct CCNativeCountClassNameTrait<className> \
{ \
    static const std::string& name; \
}; \
class className : public CCNativeCountInstances<CCNativeCountClassNameTrait<className>>

#define COUNTED_CPP_CLASS_IMPLEMENTATION_PREAMBLE(className) \
const std::string& CCNativeCountClassNameTrait<className>::name = #className; \


#else

// No-op definitions for when hookshot is not enabled.

#define PROFILE_CLASS(c)

#define PROFILE_CLASS_EXCEPT(c, e, ...)

#define PREVENT_INSTRUMENTATION(c, s)

#define CHECKPOINT(s)

#define TAG(o, s)

#define PROFILE_CPP_FUNCTION(className, name)

#define COUNTED_CPP_CLASS(className) \
class className

#define COUNTED_CPP_CLASS_IMPLEMENTATION_PREAMBLE(className)

#endif
