//
//  QMProfile.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 1/8/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMProfile.h"
#import <SSKeychain.h>

NSString *const kQMUserDataKey              = @"userData";
NSString *const kQMUserAgreementAcceptedKey = @"userAgreementAccepted";
NSString *const kQMPushNotificationsEnabled = @"pushNotificationsEnabled";
NSString *const kQMAppExists                = @"QMAppExists";

@implementation QMProfile

+ (instancetype)currentProfile {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self loadProfile];
        
        BOOL exist = [defaults boolForKey:kQMAppExists];
        
        if (_userData != nil && !exist) {
            
            [self clearProfile];
        }
    }
    
    return self;
}

- (BOOL)synchronize {
    NSParameterAssert(self.userData);
    
    if (!self.rememberMe) {
        return NO;
    }
    
    __block BOOL success = NO;
    
    @weakify(self);
    [self keychainQuery:^(SSKeychainQuery *query) {
        @strongify(self);
        query.passwordObject = self;
        NSError *error = nil;
        success = [query save:&error];
    }];
    
    if (success) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:kQMAppExists];
    }
    
    return success;
}

- (BOOL)synchronizeWithUserData:(QBUUser *)userData {
    
    self.userData = userData;
    BOOL success = [self synchronize];
    
    return success;
}

- (void)loadProfile {
    
    __block QMProfile *profile = nil;
    
    [self keychainQuery:^(SSKeychainQuery *query) {
        
        NSError *error = nil;
        BOOL success = [query fetch:&error];
        
        if (success) {
            profile = (id)query.passwordObject;
        }
    }];
    
    self.pushNotificationsEnabled = profile.pushNotificationsEnabled;
    self.userAgreementAccepted = profile.userAgreementAccepted;
    self.userData = profile.userData;
}

- (BOOL)clearProfile {
    
    __block BOOL success = NO;
    
    [self keychainQuery:^(SSKeychainQuery *query) {
        
        NSError *error = nil;
        success = [query deleteItem:&error];
    }];
    
    self.userData = nil;
    self.pushNotificationsEnabled = YES;
    self.userAgreementAccepted = NO;
    
    return success;
}

#pragma mark - Keychain

- (void)keychainQuery:(void(^)(SSKeychainQuery *query))keychainQueryBlock {
    
    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    NSString *service = [NSString stringWithFormat:@"%@.service", bundleIdentifier];
    NSString *account = [NSString stringWithFormat:@"%@.account", bundleIdentifier];
    
    SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
    query.service = service;
    query.account = account;
    
    keychainQueryBlock(query);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self) {
        
        self.userData = [aDecoder decodeObjectForKey:kQMUserDataKey];
        self.userAgreementAccepted = [aDecoder decodeBoolForKey:kQMUserAgreementAcceptedKey];
        self.pushNotificationsEnabled = [aDecoder decodeBoolForKey:kQMPushNotificationsEnabled];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.userData forKey:kQMUserDataKey];
    [aCoder encodeBool:self.userAgreementAccepted forKey:kQMUserAgreementAcceptedKey];
    [aCoder encodeBool:self.pushNotificationsEnabled forKey:kQMPushNotificationsEnabled];
}

@end
