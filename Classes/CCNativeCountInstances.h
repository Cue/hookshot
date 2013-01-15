//
//  CCNativeCountInstances.cpp
//  Cue
//
//  Created by Aaron Sarazan on 9/25/12.
//  Copyright (c) 2012 Cue, Inc. All rights reserved.


#ifndef __CCNativeCountInstances_H_
#define __CCNativeCountInstances_H_

#ifdef HOOKSHOT_ENABLED

#include <string>

class CCNativeCountInstances {

private:
    std::string _className;
    
public:
    CCNativeCountInstances(const char *className);
    virtual ~CCNativeCountInstances();
};

#endif // HOOKSHOT_ENABLED

#endif // __CCNativeCountInstances_H_
