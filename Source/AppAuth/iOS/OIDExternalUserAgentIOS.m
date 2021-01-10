/*! @file OIDExternalUserAgentIOS.m
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2016 Google Inc. All Rights Reserved.
    @copydetails
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
 */

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

#import "OIDExternalUserAgentIOS.h"

#import "OIDErrorUtilities.h"
#import "OIDExternalUserAgentSession.h"
#import "OIDExternalUserAgentRequest.h"
#import "OIDWKWebViewController.h"

#if !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_BEGIN

@interface OIDExternalUserAgentIOS ()<OIDWKWebNavigationDelegate>
@end

@implementation OIDExternalUserAgentIOS {
  UIViewController *_presentingViewController;

  BOOL _externalUserAgentFlowInProgress;
  __weak id<OIDExternalUserAgentSession> _session;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  __weak OIDWKWebViewController *_viewController;
#pragma clang diagnostic pop
}

- (nullable instancetype)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  return [self initWithPresentingViewController:nil];
#pragma clang diagnostic pop
}

- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController {
  self = [super init];
  if (self) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    NSAssert(presentingViewController != nil,
             @"presentingViewController cannot be nil on iOS 13");
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    
    _presentingViewController = presentingViewController;
  }
  return self;
}

- (BOOL)presentExternalUserAgentRequest:(id<OIDExternalUserAgentRequest>)request
                                session:(id<OIDExternalUserAgentSession>)session {
  if (_externalUserAgentFlowInProgress) {
    // TODO: Handle errors as authorization is already in progress.
    return NO;
  }

  _externalUserAgentFlowInProgress = YES;
  _session = session;
  BOOL openedUserAgent = NO;
  NSURL *requestURL = [request externalUserAgentRequestURL];

  __weak OIDExternalUserAgentIOS *weakSelf = self;
  
  NSString *redirectScheme = request.redirectScheme;

  // TODO here
  OIDWKWebViewController *wkWebViewController = [[OIDWKWebViewController alloc] initWithURL:requestURL
                                                                                catchSchema: redirectScheme
                                                                                andCallback:^(NSURL * _Nullable authorizationResponse) {
      __strong OIDExternalUserAgentIOS *strongSelf = weakSelf;

      if (!strongSelf) {
          return;
      }

      if (authorizationResponse) {
        [strongSelf->_session resumeExternalUserAgentFlowWithURL:authorizationResponse];
      } else {
        
        UIViewController *controller = _viewController;
        _viewController = nil;

        [controller dismissViewControllerAnimated:YES completion:^{
          NSError *safariError =
              [OIDErrorUtilities errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
                               underlyingError:nil
                                   description:nil];
          [strongSelf->_session failExternalUserAgentFlowWithError:safariError];
        }];
      }
  }];
  
  wkWebViewController.delegate = weakSelf;
  _viewController = wkWebViewController;

  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:wkWebViewController];

  [_presentingViewController
     presentViewController:navController
                  animated:YES
                completion:nil];

  openedUserAgent = YES;

  return openedUserAgent;
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated completion:(void (^)(void))completion {
  if (!_externalUserAgentFlowInProgress) {
    // Ignore this call if there is no authorization flow in progress.
    if (completion) completion();
    return;
  }
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  OIDWKWebViewController *controller = _viewController;
#pragma clang diagnostic pop
  
  [self cleanUp];
  if (controller) {
    // dismiss the SFSafariViewController
    [controller dismissViewControllerAnimated:YES completion:completion];
  } else {
    if (completion) completion();
  }
}

- (void)cleanUp {
  // The weak references to |_safariVC| and |_session| are set to nil to avoid accidentally using
  // them while not in an authorization flow.
  _viewController = nil;
  _session = nil;
  _externalUserAgentFlowInProgress = NO;
}

#pragma mark - WKWebViewNavigationDelegate

- (void)oIDWKWebViewControllerDidFinish:(id)controller{
  if (controller != _viewController) {
    // Ignore this call if the safari view controller do not match.
    return;
  }

  if (!_externalUserAgentFlowInProgress) {
    // Ignore this call if there is no authorization flow in progress.
    return;
  }
  id<OIDExternalUserAgentSession> session = _session;
  [self cleanUp];
  NSError *error = [OIDErrorUtilities errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
                                    underlyingError:nil
                                        description:@"No external user agent flow in progress."];
  [session failExternalUserAgentFlowWithError:error];
}

#pragma mark - SFSafariViewControllerDelegate HERE

- (void)safariViewControllerDidFinish:(UIViewController *)controller NS_AVAILABLE_IOS(9.0) {
  if (controller != _viewController) {
    // Ignore this call if the safari view controller do not match.
    return;
  }
  if (!_externalUserAgentFlowInProgress) {
    // Ignore this call if there is no authorization flow in progress.
    return;
  }
  id<OIDExternalUserAgentSession> session = _session;
  [self cleanUp];
  NSError *error = [OIDErrorUtilities errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
                                    underlyingError:nil
                                        description:@"No external user agent flow in progress."];
  [session failExternalUserAgentFlowWithError:error];
}

@end

NS_ASSUME_NONNULL_END

#endif // !TARGET_OS_MACCATALYST

#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
