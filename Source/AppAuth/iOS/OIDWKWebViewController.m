//
//  OIDWKWebViewController.m
//  AppAuth
//
//  Created by Luis Romero on 1/7/21.
//  Copyright © 2021 OpenID Foundation. All rights reserved.
//

#import "OIDWKWebViewController.h"

@import WebKit;

API_AVAILABLE(ios(8.0))
@interface OIDWKWebViewController ()

@property WKWebView *wkWebView;
@property NSURL *url;
@property NSString *successUrl;
@property OIDWKWebCallback callback;

@end

@implementation OIDWKWebViewController

@synthesize delegate;

- (id)initWithURL:(NSURL *)url catchSchema:(NSString *)successUrl andCallback:(nonnull OIDWKWebCallback)callback{
  self = [[OIDWKWebViewController alloc] init];

  self.callback = callback;
  self.url = url;
  self.successUrl = successUrl;
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                target:self
                                                                action:@selector(close)];

  return self;
}

- (void)close{
  self.callback(nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.wkWebView = [[WKWebView alloc] initWithFrame:self.view.frame];
    self.wkWebView.navigationDelegate = self;
  
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url];
    [self.wkWebView loadRequest:request];

    [self.view addSubview:self.wkWebView];

    [self setupCookies];
}

- (void)setupCookies{
  WKHTTPCookieStore *webViewStore = self.wkWebView.configuration.websiteDataStore.httpCookieStore;
  NSHTTPCookieStorage  *newCookies = NSHTTPCookieStorage.sharedHTTPCookieStorage;

  for (NSHTTPCookie *item in newCookies.cookies) {
    [webViewStore setCookie:item completionHandler:^{}];
  }
}

#pragma mark - WKNvigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSString *schema = navigationAction.request.URL.host;

  if ([navigationAction.request.URL.absoluteString hasPrefix:self.successUrl] == YES) {
    [webView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * items) {
      for (NSHTTPCookie *item in items) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:item];
      }
      
      self.callback(navigationAction.request.URL);
    }];
  }
  
  decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
  decisionHandler(WKNavigationActionPolicyAllow);
}

@end
