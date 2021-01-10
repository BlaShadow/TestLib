//
//  OIDWKWebViewController.h
//  AppAuth
//
//  Created by Luis Romero on 1/7/21.
//  Copyright © 2021 OpenID Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WKWebView.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^OIDWKWebCallback)(NSURL *_Nullable authorizationResponse);

@protocol OIDWKWebNavigationDelegate <NSObject>

@required
- (void)oIDWKWebViewControllerDidFinish:(id)controller;

@end

@interface OIDWKWebViewController : UIViewController <WKNavigationDelegate>

@property (nonatomic, weak) OIDWKWebViewController * _Nullable delegate;

- (id)initWithURL:(NSURL *)url catchSchema:(NSString *)successUrl andCallback:(OIDWKWebCallback)callback;

@end

NS_ASSUME_NONNULL_END
