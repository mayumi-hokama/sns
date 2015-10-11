#pragma mark - Facebookシェア
- (void)facebookShare {

  // 投稿用パラメータ
  self.facebookParams = [@{
                           @"name" : CPShareTitle,
                           @"caption": @"choiplus.com",
                           @"description": CPShareDescription,
                           @"link": CPWebViewURL,
                           @"message" : [NSString stringWithFormat:@"【%@】:【%@】\n%@ %@",
                                         recipeTitle,
                                         self.descriptionLabel.text,
                                         CPWebViewURL,
                                         CPShareHashTag],
                           @"picture" : @"http://1.bp.blogspot.com/-fk6xOnUwgec/VXOTxXzUaGI/AAAAAAAAuD8/NC0VtNQY7MA/s400/hidari_uma.png"} mutableCopy];

    if (self.accountStore == nil) {
        self.accountStore = [ACAccountStore new];
    }

    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];  //  Facebookを指定

    // step.1 email取得
    NSDictionary *options = @{ ACFacebookAppIdKey : CPFacebookAppId,
                               ACFacebookAudienceKey : ACFacebookAudienceFriends,
                               ACFacebookPermissionsKey : @[@"email"] };
    [self.accountStore
     requestAccessToAccountsWithType:accountType
     options:options
     completion:^(BOOL granted, NSError *error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (granted) {
                 NSLog(@"OK");
                 // ユーザーがFacebookアカウントへのアクセスを許可した
                 self.facebookAccounts = [self.accountStore accountsWithAccountType:accountType];
                 if (self.facebookAccounts.count > 0) {
                     if ([self.facebookAccounts count] == 1) {
                         [self setFacebook:0];
                         [self sendFacebook:0];
                         return;
                     }
                     // 複数アカウントの場合
                     // （Facebookは基本1こだから通らないかも...）
                     UIAlertController * ac = [UIAlertController alertControllerWithTitle:nil
                                                                                  message:@"使用するアカウントを選択してください。"
                                                                           preferredStyle:UIAlertControllerStyleActionSheet];

                     // Cancel用のアクションを生成
                     UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                             style:UIAlertActionStyleCancel
                                                                           handler:^(UIAlertAction * action) {
                                                                               // ボタンタップ時の処理
                                                                               NSLog(@"Cancel button tapped.");
                                                                           }];

                     // 設定されているアカウント分作成
                     for (int i=0; i < self.facebookAccounts.count; i++) {
                         UIAlertAction * addAction =
                         [UIAlertAction actionWithTitle:self.facebookAccounts[i]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action){
                                                    [self setFacebook:i];
                                                    [self sendFacebook:i];
                                                }];

                         [ac addAction:addAction];
                     }
                     // コントローラにアクションを追加
                     [ac addAction:cancelAction];
                     // アクションシート表示処理
                     [self presentViewController:ac animated:YES completion:nil];
                 }
             } else {
                 if([error code]== ACErrorAccountNotFound){
                     //  iOSに登録されているFacebookアカウントがありません。
                     NSLog(@"Facebookアカウントが登録されていません。");
                 } else {
                     // ユーザーが許可しない
                     // 設定→Facebook→アカウントの使用許可するApp→YOUR_APPをオンにする必要がある
                     NSLog(@"Facebookが有効になっていません。");
                 }
             }
         });
     }];
}
#pragma mark - FacebookAccount情報のせっと
-(void)setFacebook:(NSInteger)index {
    ACAccount *facebookAccount = self.facebookAccounts[index];
    // メールアドレスを取得する
    NSString *email = [[facebookAccount valueForKey:@"properties"] objectForKey:@"ACUIDisplayUsername"];

    // アクセストークンを取得する
    ACAccountCredential *facebookCredential = [facebookAccount credential];
    NSString *accessToken = [facebookCredential oauthToken];
}

#pragma mark - Facebook投稿API
-(void)sendFacebook:(NSInteger)index {

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *facebookType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

    NSDictionary *options = @{ACFacebookAppIdKey :CPFacebookAppId,
                              ACFacebookPermissionsKey : @[@"publish_actions"],
                              ACFacebookAudienceKey : ACFacebookAudienceFriends};


    [accountStore requestAccessToAccountsWithType:facebookType options:options completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{

            if(granted){
                NSString *urlStr = [NSString stringWithFormat:@"https://graph.facebook.com/me/feed"];
                NSURL *url = [NSURL URLWithString:urlStr];

                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:url parameters:self.facebookParams];

                [request setAccount:self.facebookAccounts[index]];
                [request performRequestWithHandler:^(NSData *response, NSHTTPURLResponse *urlResponse, NSError *error){
                    NSLog(@"response:%@",[[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding]);
                }];
            }
        });
    }];
}

#pragma mark - Twitterシェア
- (void)twitterShare {

  self.twitterParams = [@{
                         @"status":[NSString stringWithFormat:@"【%@】:【%@】\n%@ %@",
                                    recipeTitle,
                                    self.descriptionLabel.text,
                                    CPWebViewURL,
                                    CPShareHashTag],
                         @"image":@"http://1.bp.blogspot.com/-fk6xOnUwgec/VXOTxXzUaGI/AAAAAAAAuD8/NC0VtNQY7MA/s400/hidari_uma.png"
                         } mutableCopy];

    if (self.accountStore == nil) {
        self.accountStore = [ACAccountStore new];
    }

    // Twitterを指定
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    // step.1 email取得
    [self.accountStore requestAccessToAccountsWithType:accountType
                                               options:nil
                                            completion:^(BOOL granted, NSError *error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (granted) {
                 // ユーザーがTwitterアカウントへのアクセスを許可した
                 self.twitterAccounts = [self.accountStore accountsWithAccountType:accountType];
                 if (self.twitterAccounts.count > 0) {
                     if ([self.twitterAccounts count] == 1) {
                         [self sendTwitter:0];
                         return;
                     }
                     // 複数アカウントの場合
                     UIAlertController * ac = [UIAlertController alertControllerWithTitle:nil
                                                                                  message:@"使用するアカウントを選択してください。"
                                                                           preferredStyle:UIAlertControllerStyleActionSheet];

                     // Cancel用のアクションを生成
                     UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                             style:UIAlertActionStyleCancel
                                                                           handler:^(UIAlertAction * action) {
                                                                               // ボタンタップ時の処理
                                                                               NSLog(@"Cancel button tapped.");
                                                                           }];
                     // 設定されているアカウント分
                     for (int i=0; i < self.twitterAccounts.count; i++) {
                         UIAlertAction * addAction =
                         [UIAlertAction actionWithTitle:[self.twitterAccounts[i] accountDescription]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action){
                                                    [self sendTwitter:i];
                                                }];

                         [ac addAction:addAction];
                     }
                     // コントローラにアクションを追加
                     [ac addAction:cancelAction];
                     // アクションシート表示処理
                     [self presentViewController:ac animated:YES completion:nil];
                 }
             } else {
                 if([error code]== ACErrorAccountNotFound){
                     //  iOSに登録されているtwitterアカウントがありません。
                     NSLog(@"Twitterアカウントが登録されていません。");
                 } else {
                     // ユーザーが許可しない
                     // 設定→Twitter→アカウントの使用許可するApp→YOUR_APPをオンにする必要がある
                     NSLog(@"Twitterアカウントが有効になっていません。");
                 }
             }
         });
     }];
}

#pragma mark - Twitter画像投稿
// upload_with_mediaが非推奨になっているため、media/upload.json → statuses/update.jsonを実行
- (void)sendTwitter:(NSInteger)index
{
    ACAccount *twitterAccount = self.twitterAccounts[index];

    NSString *endpoint = @"https://upload.twitter.com/1.1/media/upload.json";
    NSData *dt = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.twitterParams[@"image"]]];
    UIImage *image = [[UIImage alloc] initWithData:dt];
    NSData* imageData = UIImagePNGRepresentation(image);
    NSDictionary *parameters = @{@"media":[imageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]};


    NSURL *url = [NSURL URLWithString:endpoint];
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:parameters];

    [request setAccount:twitterAccount];
    [request performRequestWithHandler:^(NSData *response, NSHTTPURLResponse *urlResponse, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"error %@", error);
            if (urlResponse.statusCode == 200) {
                NSError *jsonError = nil;
                id jsonData = [NSJSONSerialization JSONObjectWithData:response
                                                              options:NSJSONReadingMutableContainers
                                                                error:&jsonError];
                if (jsonError) {
                    NSLog(@"Error: %@", jsonError);
                    return;
                }
                NSLog(@"Result : %@", jsonData);
                NSString *mediaId = jsonData[@"media_id_string"];
                [self.twitterParams removeObjectForKey:@"image"];
                self.twitterParams[@"media_ids"] = mediaId;
                [self updateTwitter:index];
            }
            else {
                NSLog(@"投稿できませんでした\nstatus code : %ld", (long)urlResponse.statusCode);
            }
            NSLog(@"response:%@",[[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding]);
        });
    }];
}
#pragma mark - twitter投稿
-(void)updateTwitter:(NSInteger)index {

    ACAccount *twitterAccount = self.twitterAccounts[index];

    NSString *urlStr = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/update.json"];
    NSURL *url = [NSURL URLWithString:urlStr];

    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url parameters:self.twitterParams];

    [request setAccount:twitterAccount];
    [request performRequestWithHandler:^(NSData *response, NSHTTPURLResponse *urlResponse, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"error %@", error);
            if (urlResponse.statusCode == 200) {
                NSLog(@"投稿しました。");
            }
            else {
                NSLog(@"投稿できませんでした\nstatus code : %ld", (long)urlResponse.statusCode);
            }
            NSLog(@"response:%@",[[NSString alloc]initWithData:response encoding:NSUTF8StringEncoding]);
        });
    }];
}
