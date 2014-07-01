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
    // TODO:  [downloadTwitterObject setTitle:@"멈춰"];
    [self downloadTwitterObjectRunner:nil];
}

- (IBAction)checkUnfavoriteUserId:(id)sender
{
    
}

NSString *descriptionForTarget(NSDictionary *target) {
    //NSString *timestamp = [target valueForKey:@"created_at"];
    NSString *targetName = [target valueForKeyPath:@"user.screen_name"];
    NSString *text = [target valueForKey:@"text"];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"\n                                    "];
    NSString *favouritesCount = [target valueForKey:@"favorite_count"];
    NSString *retweetsCount = [target valueForKey:@"retweet_count"];
    NSString *idString = [target valueForKey:@"id_str"];
    
    return [NSString stringWithFormat:@"%@\t[F %@] [R %@]\t@%@\t%@", idString, favouritesCount, retweetsCount, targetName, text];
}

NSString *descriptionForFavorites(NSArray *favorites) {
    
    NSMutableString *ms = [NSMutableString string];
    
    NSUInteger numberOfFavorites = 0;
    
    for(NSDictionary *d in favorites) {
        [ms appendString:@"----------\n"];
        
        NSString *timestamp = [d valueForKey:@"created_at"];
        
        for(NSDictionary *source in [d valueForKey:@"sources"]) {
            NSString *sourceName = [source valueForKey:@"screen_name"];
            
            [ms appendFormat:@"%@ @%@ favorited:\n", timestamp, sourceName];
        }
        
        NSArray *targets = [d valueForKey:@"targets"];
        
        numberOfFavorites += [targets count];
        
        for(NSDictionary *target in targets) {
            
            NSString *targetDescription = descriptionForTarget(target);
            
            [ms appendFormat:@"%@\n", targetDescription];
        }
    }
    
    return ms;
}

#if 0
    // TODO: screen name
    NSArray *favorites = [statues filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSDictionary *d = (NSDictionary *)evaluatedObject;
        return [[d valueForKey:@"action"] isEqualToString:@"favorite"];
    }]];

    NSString *timestamp = [d valueForKey:@"created_at"];
    NSUInteger index = [array indexOfObject:max];
#endif

- (void)downloadTwitterObjectRunner:(NSString*)maximumID
{
    NSString *tweetCount = @"200";
    
    void (^fetchTweets)(NSArray*) = ^(NSArray* favorites) {
        for (NSDictionary *dic in favorites) {
            NSDictionary *medias = dic[@"extended_entities"][@"media"];
            for (NSDictionary *media in medias)
            {
                NSURL *uri = media[@"media_url"];
                NSLog(@"%@", uri);
                NSData *data = [NSData dataWithContentsOfURL:uri options:NSDataReadingUncached error:nil];
            }
        }
        
    };
    
    
    void (^fetchFavorite)(NSArray*) = ^(NSArray* statues) {
        // stop if final place reaches.
        // BUG_FIX: 그냥 막 0 개 들어오네?
        if (statues.count != 0 && statues.count < [tweetCount integerValue])
        {
            NSLog(@"Finished!");
        }
        else
        {
            fetchTweets(statues);
            
            NSArray *ids = [statues valueForKeyPath:@"id"];
            NSString *maxID = [[ids valueForKeyPath:@"@max.intValue"] stringValue];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self downloadTwitterObjectRunner:maxID];
            });
        }
    };
    
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
