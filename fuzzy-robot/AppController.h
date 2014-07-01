//
//  AppController.h
//  fuzzy-robot
//
//  Created by newpolaris on 6/30/14.
//  Copyright (c) 2014 newpolaris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import "STTwitter.h"

@class AppController;

@protocol STAuthenticationVCDelegate
- (void)authenticationVC:(AppController *)sender didChangeTwitterObject:(STTwitterAPI *)twitter;
@end

@interface AppController : NSObject {
@private
    IBOutlet NSPopUpButton *osxAccountsPopupBtn;
    IBOutlet NSTextField *loginStatus;
    IBOutlet NSTextField *outputFolder;
    IBOutlet NSButton *openFolder;
    IBOutlet NSButton *changeFolder;
    IBOutlet NSButton *saveTwitterObject;
    IBOutlet NSTextField *statusSummary;
    IBOutlet NSTextField *statusProcess;
    IBOutlet NSTextField *unfavoritedUsersID;
}

@property (nonatomic, retain) STTwitterAPI *twitter;
@property (nonatomic, assign) id <STAuthenticationVCDelegate> delegate;
@property (nonatomic, retain) NSArray *osxAccounts;
@property (nonatomic, strong) ACAccountStore *accountStore;

- (IBAction)twitterLogin:(id)sender;
- (IBAction)checkOutFolder:(id)sender;
- (IBAction)setOutFolder:(id)sender;
- (IBAction)openFolder:(id)sender;
- (IBAction)downloadTwitterObject:(id)sender;
- (IBAction)checkUnfavoriteUserId:(id)sender;

- (void)twitterLoginTry;

@end
