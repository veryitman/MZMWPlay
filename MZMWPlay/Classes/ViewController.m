//
//  ViewController.m
//  MZMWPlay
//
//  Created by mark.zhang on 09/05/2017.
//  Copyright © 2017 veryitman. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <HTTPServer.h>
#import "AppDelegate.h"

static NSString * const sSnakeGameDirName = @"crazySnake";

@interface ViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) HTTPServer *localHttpServer;

@property (nonatomic, strong) WKWebViewConfiguration *wbConfig;

@property (nonatomic, strong) IBOutlet UILabel *loadingLb;

@property (nonatomic, assign) BOOL startServerSuccess;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.loadingLb.text = @"Config server...";
        [self _configLocalHttpServer];
    });
    
    /// 增加的调式方法: 可以重新启动 web server.
    {
        SEL sel = @selector(_configLocalHttpServer);
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:sel];
        [self.loadingLb addGestureRecognizer:gesture];
        self.loadingLb.userInteractionEnabled = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 配置 WKWebView
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        _wbConfig = [[WKWebViewConfiguration alloc] init];
        self.wbConfig.userContentController = [[WKUserContentController alloc] init];
        
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:self.wbConfig];
        
        _webView.frame = self.view.bounds;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        _webView.scrollView.showsVerticalScrollIndicator   = NO;
        
        [self.view addSubview:self.webView];
        self.webView.frame = self.view.bounds;
        self.webView.navigationDelegate = self;
        
        if (self.startServerSuccess) {
            self.loadingLb.hidden = YES;
            
            NSString *gameUrl = [[NSBundle mainBundle] pathForResource:@"index"
                                                                ofType:@"html"
                                                           inDirectory:sSnakeGameDirName];
            NSURL *url = [NSURL fileURLWithPath:gameUrl];
            
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%@/index.html", self.port]];
            [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        }
    });
}

#pragma mark - WKWebView Delegage.

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"shouldStartLoadWithRequest. navigation: %@", navigation);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"didFinishNavigation");
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"didFailNavigation, error: %@", error);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"didFailNavigation, error: %@", error);
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"didFailNavigation, webView: %@", webView);
}

#pragma mark - Private.

- (void)_configLocalHttpServer
{
    NSString *webPath = [[NSBundle mainBundle] pathForResource:sSnakeGameDirName ofType:nil];
    _localHttpServer = [[HTTPServer alloc] init];
    [_localHttpServer setType:@"_http.tcp"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSLog(@"%@", webPath);
    
    if (![fileManager fileExistsAtPath:webPath]) {
        NSLog(@"File path error!");
    }
    else {
        NSString *webLocalPath = webPath;
        [_localHttpServer setDocumentRoot:webLocalPath];
        NSLog(@"webLocalPath:%@", webLocalPath);
        [self _startWebServer];
    }
}

- (void)_startWebServer
{
    self.loadingLb.hidden = NO;
    
    NSError *error;
    if ([_localHttpServer start:&error]) {
        NSLog(@"Started HTTP Server on port %hu", [_localHttpServer listeningPort]);
        self.port = [NSString stringWithFormat:@"%d", [_localHttpServer listeningPort]];
        
        self.loadingLb.text = @"Start Server Successfully.";
        
        _startServerSuccess = YES;
    }
    else {
        NSLog(@"Error starting HTTP Server: %@", error);
        
        self.loadingLb.text = @"Start Server failed.";
        
        _startServerSuccess = NO;
    }
}

@end
