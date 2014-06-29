//
//  AppDelegate.m
//  fuzzy-robot
//
//  Created by newpolaris on 6/29/14.
//  Copyright (c) 2014 newpolaris. All rights reserved.
//

#import "AppDelegate.h"
#import <Accounts/Accounts.h>

@interface AppDelegate ()
@property (nonatomic, strong) ACAccountStore *accountStore;
@end

@implementation AppDelegate


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [_accountStore requestAccessToAccountsWithType:twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
        if(granted == NO) return;
        self.osxAccounts = [_accountStore accountsWithAccountType:twitterAccountType];
    }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

@end
