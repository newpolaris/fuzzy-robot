//
//  AppController.m
//  fuzzy-robot
//
//  Created by newpolaris on 6/30/14.
//  Copyright (c) 2014 newpolaris. All rights reserved.
//

#import "AppController.h"
#import "TFHpple.h"

@implementation AppController

- (IBAction)twitterLogin:(id)sender {
    [self twitterLoginTry];
}

- (void)checkOutFolder {
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
    [self checkOutFolder];
    [self checkUnfavoriteUserId];
    // GET statuses/user_timeline
    [self.twitter getAccountVerifyCredentialsWithSuccessBlock:^(NSDictionary *account) {
        self.favourites_count = [[account valueForKey:@"favourites_count"] integerValue];
    } errorBlock:^(NSError *error) {
        self.favourites_count = 200;
    }];

    @autoreleasepool {
    // TODO:  [downloadTwitterObject setTitle:@"멈춰"];
    [self downloadTwitterObjectRunner:nil];
    }
}

- (void)checkUnfavoriteUserId
{
    NSString *string = unfavoritedUsersID.stringValue;
    NSArray* list = [string componentsSeparatedByString:@"@"];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (NSString* user in list)
    {
       if([user length] == 0)
           continue;
    
       if(![[user stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
           continue;
       }
       [array addObject:[user stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    
    self.unfavorittedUserList = array;
}

-(void)fetchTweets:(NSArray*)favorites
{
    if ([favorites count] == 0) return;
    
    dispatch_apply([favorites count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t idx) {
        NSDictionary *dic = [favorites objectAtIndex: idx];
        @autoreleasepool {
            NSDictionary *medias = dic[@"extended_entities"][@"media"];
            NSDictionary *urls = dic[@"entities"][@"urls"];
            
            NSMutableArray *uriArr = [[NSMutableArray alloc] init];
            NSMutableArray *fileArr = [[NSMutableArray alloc] init];
            NSMutableArray *nameArr = [[NSMutableArray alloc] init];
            
            if (medias != nil)
            {
                for (NSDictionary *media in medias)
                {
                    NSURL *uri = [NSURL URLWithString:[media[@"media_url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    NSURL *largeImageUri = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", uri, @":orig"]];
                    
                    [fileArr addObject:[uri lastPathComponent]];
                    [uriArr addObject:largeImageUri];
                    [nameArr addObject:dic[@"user"][@"screen_name"]];
                }
            }
            else if (urls != nil)
            {
                for (NSDictionary *url in urls)
                {
                    NSString *uri = url[@"expanded_url"];
                    if (uri == nil) continue;
                    if ([uri rangeOfString:@"twitter.com"].length == 0) continue;
                    
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", uri]];
                    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:nil];
                    TFHpple *parser = [[TFHpple alloc] initWithHTMLData:data];
                    NSArray *elements = [parser searchWithXPathQuery:@"//source[@class='source-mp4']"];
                    
                    for (TFHppleElement *link in elements)
                    {
                        NSString *mp4link = [link objectForKey:@"video-src"];
                        if (mp4link == nil) continue;
                        NSURL *mp4uri = [NSURL URLWithString:[NSString stringWithFormat:@"%@", mp4link]];
                        
                        [fileArr addObject:[mp4uri lastPathComponent]];
                        [uriArr addObject:mp4uri];
                        [nameArr addObject:dic[@"user"][@"screen_name"]];
                    }
                }
            }
            
            if (uriArr.count == 0) return;
            
            NSFileManager* fileManager = [[NSFileManager alloc] init];
            
            for (int i = 0; i < uriArr.count; i++)
            {
                @autoreleasepool {
                    NSArray *dirComp = [NSArray arrayWithObjects:[outputFolder stringValue], nameArr[i], nil];
                    NSString *directory = [NSString pathWithComponents:dirComp];
                    
                    BOOL isDir;
                    if(![fileManager fileExistsAtPath:directory isDirectory:&isDir])
                        if(![fileManager createDirectoryAtPath:directory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:NULL])
                            NSLog(@"Error: Create folder failed %@", directory);
                    
                    NSArray *components = [NSArray arrayWithObjects:[outputFolder stringValue], nameArr[i], fileArr[i], nil];
                    NSString *path = [NSString pathWithComponents:components];
                    
                    if (![fileManager fileExistsAtPath:path]) {
                        NSURL *uri = uriArr[i];
                        NSData *data = [NSData dataWithContentsOfURL:uri
                                                             options:NSDataReadingUncached
                                                               error:nil];
                        [data writeToFile:path atomically:YES];
                        [self updateStatusProcess:[NSString stringWithFormat:@"Saved: %@/%@", nameArr[i], fileArr[i]]];
                    }
                    else
                    {
                        [self updateStatusProcess:[NSString stringWithFormat:@"파일이 이미 존재함: %@/%@", nameArr[i], fileArr[i]]];
                    }
                }
            }
            
            NSString *content = dic[@"text"];
            if (content != nil)
            {
                NSString* file = [[fileArr[0] stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"];
                NSArray* componets = [NSArray arrayWithObjects:[outputFolder stringValue], nameArr[0], file, nil];
                NSString* filePath = [NSString pathWithComponents:componets];
                //save content to the documents directory
                if (![fileManager fileExistsAtPath:filePath]) {
                    NSError *error;
                    if (![content writeToFile:filePath
                                   atomically:YES
                                     encoding:NSUTF8StringEncoding
                                        error:&error])
                    {
                        NSLog(@"ERROR SAVE TEXT:%@", [error debugDescription]);
                    }
                    
                    
                    [self updateStatusProcess:
                     [NSString stringWithFormat:@"Saved: %@/%@", nameArr[0], file]];
                }
            }
        
            for (NSString* userName in self.unfavorittedUserList)
            {
                NSString *name = dic[@"user"][@"screen_name"];
                if (name == nil) continue;
                if ([userName isEqualToString:name])
                {
                    NSString *id_str = dic[@"id_str"];
                    NSString *text = [NSString stringWithFormat:@"%@ 트윗은 이제 지워졌습니다.", id_str];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.twitter postFavoriteDestroyWithStatusID:id_str
                                                      includeEntities:@(NO)
                                                         successBlock:^(NSDictionary *status) {
                                                             [self updateStatusProcess:text]                                          ;
                                                         }
                                                           errorBlock:^(NSError *error) {
                                                               NSLog(@"에러 났어여..%@", [error debugDescription]);
                                                           }];
                    });
                    break;
                }
            }
        }
    });
    
    self.favourites_count -= favorites.count;
    [self updateStatusSummary:[NSString stringWithFormat:@"Remain: %ld", (long)self.favourites_count]];
};

- (void)updateStatusProcess:(NSString*)string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[statusProcess textStorage] beginEditing];
        [[[statusProcess textStorage] mutableString] appendString:string];
        [[[statusProcess textStorage] mutableString] appendString:@"\n"];
        [[statusProcess textStorage] endEditing];
        
        NSRange range;
        range = NSMakeRange ([[statusProcess string] length], 0);
        [statusProcess scrollRangeToVisible:range];
    });
}

- (void)updateStatusSummaryWithoutSync:(NSString*)string
{
    [[statusSummary textStorage] beginEditing];
    [[[statusSummary textStorage] mutableString] appendString:string];
    [[[statusSummary textStorage] mutableString] appendString:@"\n"];
    [[statusSummary textStorage] endEditing];
    
    NSRange range;
    range = NSMakeRange ([[statusSummary string] length], 0);
    [statusSummary scrollRangeToVisible: range];
}

- (void)updateStatusSummary:(NSString*)string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatusSummaryWithoutSync:string];
    });
}

- (void)downloadTwitterObjectRunner:(NSString*)maximumID
{
    void(^fetchFavorite)(NSArray*) = ^(NSArray* statues){
        // stop if final place reaches.
        // BUG_FIX: 그냥 막 0 개 들어오네?
        if (self.favourites_count <= 0)
        {
            [self updateStatusSummary:@"다 끝났습니다"];
        }
        else
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self fetchTweets:statues];
                
                NSArray *ids = [statues valueForKeyPath:@"id"];
                NSString* str = [[ids lastObject] stringValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self downloadTwitterObjectRunner:str];
                });
            });
        }
    };
    
    [self.twitter getFavoritesListWithUserID:nil
                                  screenName:nil
                                       count:@"200"
                                     sinceID:nil
                                       maxID:maximumID
                             includeEntities:@(YES)
                                successBlock:fetchFavorite
                                  errorBlock:^(NSError *error) {
                                      NSLog(@"%@", [error debugDescription]);
                                      if ([error code] == 88)
                                      {
                                          [self updateStatusSummaryWithoutSync:
                                            [NSString stringWithFormat:@"Limit에 걸렸습니다. 1분 후에 재시도 합니다.\n %@",
                                             [error debugDescription]]];
                                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                                                       (int64_t)(60 * 1 * NSEC_PER_SEC)),
                                                         dispatch_get_main_queue(), ^{
                                                             [self downloadTwitterObjectRunner:maximumID];
                                                         });
                                      }
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
        
        [self.twitter getAccountVerifyCredentialsWithSuccessBlock:^(NSDictionary *account) {
            self.userID = account[@"id_str"];
            self.favourites_count = [[account valueForKey:@"favourites_count"] integerValue];
        } errorBlock:^(NSError *error) {
        }];
        
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
    
    NSString* pictureFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Pictures/Twitter"];
    [outputFolder setStringValue:pictureFolder];
    [statusProcess setContinuousSpellCheckingEnabled:NO];
    [statusSummary setContinuousSpellCheckingEnabled:NO];
}


@end
