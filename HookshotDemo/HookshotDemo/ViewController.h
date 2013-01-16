//
//  ViewController.h
//  HookshotDemo
//
//  Created by Robby Walker on 1/15/13.
//  Copyright (c) 2013 Cue. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * View controller for the demo.
 */
@interface ViewController : UIViewController <UIWebViewDelegate> {
    UIWebView *_webView;
}

/**
 * A web view shown in the view.
 */
@property (nonatomic, retain) IBOutlet UIWebView *webView;

@end
