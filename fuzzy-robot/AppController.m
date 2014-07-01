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
    [self twitterLoginTry];
}

- (IBAction)checkOutFolder:(id)sender {
    BOOL isDir;
    NSString* folderName = [outputFolder stringValue];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isExist = [fm fileExistsAtPath:folderName isDirectory:&isDir];
    
    if (isExist && !isDir)
    {
        NSAlert* alert = [NSAlert alertWithMessageText:@"파일 이름과 폴더이름이 같다니 이럴수가."
                 defaultButton:nil
                 alternateButton:nil
                 otherButton:nil
                 informativeTextWithFormat:@"입력된 폴더 경로와 일치하는 파일 이름이 존재합니다."];
        
        [alert runModal];
        
        NSString* pictureFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Pictures/"];
        [outputFolder setStringValue:pictureFolder];
    }
    else if (!isExist)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:folderName
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:nil];
    }
}


- (IBAction)setOutFolder:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    if ([panel runModal] != NSFileHandlingPanelOKButton) return;
    
    NSString *folder = [[panel URLs] lastObject];
    [outputFolder setStringValue:folder];
}

- (IBAction)openFolder:(id)sender
{
    NSURL *folderURL = [NSURL fileURLWithPath: [outputFolder stringValue]];
    [[NSWorkspace sharedWorkspace] openURL:folderURL];
}

- (IBAction)downloadTwitterObject:(id)sender
{
    __block BOOL bContinue = YES;
    __block NSString *tweetCount = @"200";
    __block NSString *maximumID = nil;
    
    void (^fetchFavorite)(NSArray*) = ^(NSArray* statues) {
        
        
        // stop if final place reaches.
        if (statues.count < [tweetCount integerValue])
            bContinue = NO;
    };
    
    while (bContinue) {
        [self.twitter getFavoritesListWithUserID:nil
                                      screenName:nil
                                           count:tweetCount
                                         sinceID:nil
                                           maxID:maximumID
                                 includeEntities:@(YES)
                                    successBlock:fetchFavorite
                                      errorBlock:^(NSError *error) {
                                      }];
    }
    
}

- (IBAction)checkUnfavoriteUserId:(id)sender
{
}

- (void)twitterLoginTry {
    NSInteger index = [osxAccountsPopupBtn indexOfSelectedItem];
    
    ACAccount *account = nil;
    if (index >= 0) account = self.osxAccounts[index];
    
    if(account == nil) {
        [loginStatus setStringValue:@"No account, cannot login."];
        return;
    }
    
    self.twitter = [STTwitterAPI twitterAPIOSWithAccount:account];
    
    [loginStatus setStringValue:@"-"];
    
    [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        [loginStatus setStringValue:[NSString stringWithFormat:@"Access granted for %@", username]];
        [_delegate authenticationVC:self didChangeTwitterObject:_twitter]; // update username
    } errorBlock:^(NSError *error) {
        [loginStatus setStringValue:[error localizedDescription]];
    }];
}

- (void)setTwitter:(STTwitterAPI *)twitter {
    _twitter = twitter;
    [_delegate authenticationVC:self didChangeTwitterObject:twitter];
}

- (void)awakeFromNib {
    self.accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:
                                            ACAccountTypeIdentifierTwitter];
    
    void (^loginCheck)(BOOL, NSError*) = 
    ^(BOOL granted, NSError *error) {
        if(granted == NO)
        {
            [loginStatus setTextColor:NSColor.redColor];
            [loginStatus setStringValue:@"트위터 계정을 불러 올수 없어여-맥에 트위터 계정을 등록하세요"];
        }
        else
        {
            [loginStatus setTextColor:NSColor.blackColor];
            [loginStatus setStringValue:@"로그인 진행"];
            
            self.osxAccounts = [_accountStore accountsWithAccountType:twitterAccountType];
            for (int i = 0; i < self.osxAccounts.count; i++)
            {
                NSString* username = [self.osxAccounts[i] username];
                [osxAccountsPopupBtn addItemWithTitle:username];
            }
            [self twitterLoginTry]; // 0 번째 계정으로 자동 로그인 진행.
        }
    };
    
    [_accountStore requestAccessToAccountsWithType:twitterAccountType
                                           options:nil
                                        completion:loginCheck];
    
    NSString* pictureFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Pictures/"];
    [outputFolder setStringValue:pictureFolder];
}



@end
