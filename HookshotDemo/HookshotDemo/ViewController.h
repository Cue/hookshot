//
//  ViewController.h
//  HookshotDemo
//
//  Created by Robby Walker on 1/15/13.
//  Copyright (c) 2013 Cue. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    UIWebView *_webView;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;

@end
