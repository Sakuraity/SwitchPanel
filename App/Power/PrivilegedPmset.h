#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

/// Runs `/usr/bin/pmset` with a prepared `AuthorizationRef` (C wrapper; API unavailable from Swift).
OSStatus SPAuthorizationRunPmset(AuthorizationRef authRef, NSArray<NSString *> *arguments);

NS_ASSUME_NONNULL_END