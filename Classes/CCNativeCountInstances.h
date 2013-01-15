//
//  CCNativeCountInstances.cpp
//  Cue
//
//  Created by Aaron Sarazan on 9/25/12.
//  Copyright (c) 2012 Cue, Inc. All rights reserved.


#ifndef __CCNativeCountInstances_H_
#define __CCNativeCountInstances_H_

#include <string>

class CCNativeCountInstances {

#ifdef HOOKSHOT_ENABLED
private:
    std::string _className;
#endif
    
public:
    CCNativeCountInstances(const char *className);
    virtual ~CCNativeCountInstances();
};

#endif //__CCNativeCountInstances_H_
