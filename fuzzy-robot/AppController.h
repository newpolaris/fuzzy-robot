//
//  AppController.h
//  fuzzy-robot
//
//  Created by newpolaris on 6/30/14.
//  Copyright (c) 2014 newpolaris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

@interface AppController : NSObject {
@private
    IBOutlet NSPopUpButton *osxAccountsPopupBtn;
}

@property (nonatomic, retain) NSArray *osxAccounts;
@property (nonatomic, strong) ACAccountStore *accountStore;

- (IBAction)twitterLogin:(id)sender;

@end
