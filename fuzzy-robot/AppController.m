//
//  AppController.m
//  fuzzy-robot
//
//  Created by newpolaris on 6/30/14.
//  Copyright (c) 2014 newpolaris. All rights reserved.
//

#import "AppController.h"

@implementation AppController


- (IBAction)twitterLogin:(id)sender {
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [_accountStore requestAccessToAccountsWithType:twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
        if(granted == NO) return;
        self.osxAccounts = [_accountStore accountsWithAccountType:twitterAccountType];
        for (int i = 0; i < self.osxAccounts.count; i++)
        {
            NSString* username = [self.osxAccounts[i] username];
            [osxAccountsPopupBtn addItemWithTitle:username];
        }
    }];
}


@end
