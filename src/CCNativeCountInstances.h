//
//  CCNativeCountInstances.cpp
//  Cue
//
//  Created by Aaron Sarazan on 9/25/12.
//  Copyright (c) 2012 Cue, Inc. All rights reserved.


#ifndef __CCNativeCountInstances_H_
#define __CCNativeCountInstances_H_

#ifdef GREPLIN_DEBUG
#define CC_NATIVE_COUNT
#endif

// Really verbose. Turn back on when needed.
#undef CC_NATIVE_COUNT

#include <string>

class CCNativeCountInstances {

#ifdef CC_NATIVE_COUNT
private:
    std::string _className;
#endif
    
public:
    CCNativeCountInstances(const char *className);
    virtual ~CCNativeCountInstances();
};

#endif //__CCNativeCountInstances_H_
