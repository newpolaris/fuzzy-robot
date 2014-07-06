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
    IBOutlet NSButton *changeFolder;
    IBOutlet NSButton *downloadTwitterObject;
    IBOutlet NSTextView *statusSummary;
    IBOutlet NSTextView *statusProcess;
    IBOutlet NSTextField *unfavoritedUsersID;
}

@property (nonatomic, assign) id <STAuthenticationVCDelegate> delegate;
@property (nonatomic, strong) NSArray *osxAccounts;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) STTwitterAPI *twitter;
@property (atomic, strong) NSArray *unfavorittedUserList;
@property (atomic) NSInteger favourites_count;

- (IBAction)twitterLogin:(id)sender;
- (IBAction)setOutFolder:(id)sender;
- (IBAction)openFolder:(id)sender;
- (IBAction)downloadTwitterObject:(id)sender;

- (void)twitterLoginTry;
- (void)checkUnfavoriteUserId;
- (void)checkOutFolder;

@end
