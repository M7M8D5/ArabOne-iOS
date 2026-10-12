/* ==========================================================================
   ArabOne — غلاف الموقع (WKWebView)

   الهدف الوحيد: يفتح arabone.xyz ويبقي المايك حيًّا في الخلفية.

   السر: UIBackgroundModes = audio في Info.plist. معها يبقى WKWebView
   (والمايك معه) شغّالًا وأنت داخل روبلوكس أو الشاشة مطفأة — على iOS 17.5+
   (تقرير WebKit 233419 المؤرشف 2024). بدونها يكتم iOS المايك فور الخروج.

   لا واجهة إضافية ولا شاشات: الموقع هو التطبيق.
   ========================================================================== */
#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <WKNavigationDelegate, WKUIDelegate>
@property (strong, nonatomic) WKWebView *web;
@end

static NSString * const SITE = @"https://arabone.xyz/";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.02 alpha:1.0];

    /* جلسة صوتية: تشغيل مستمر، يمزج مع تطبيقات أخرى، يعمل في الخلفية.
       هذا مع UIBackgroundModes=audio هو ما يمنع iOS من قتل الصوت. */
    NSError *err = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:AVAudioSessionCategoryOptionMixWithOthers
                    error:&err];
    [session setActive:YES error:&err];

    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.allowsInlineMediaPlayback = YES;
    cfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    self.web = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.web.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.web.navigationDelegate = self;
    self.web.UIDelegate = self;
    [self.view addSubview:self.web];

    NSURL *url = [NSURL URLWithString:SITE];
    [self.web loadRequest:[NSURLRequest requestWithURL:url]];
}

/* الروابط الخارجية (ديسكورد، X، يوتيوب) تفتح في تطبيقاتها */
- (WKNavigationActionPolicy)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)action
                    decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    NSURL *u = action.request.URL;
    if (action.navigationType == WKNavigationTypeLinkActivated &&
        ![u.host isEqualToString:@"arabone.xyz"]) {
        [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil];
        handler(WKNavigationActionPolicyCancel);
        return;
    }
    handler(WKNavigationActionPolicyAllow);
}

/* إذن المايك: نمرر طلب الموقع لنظام iOS ونرجع جوابه */
- (void)webView:(WKWebView *)webView
    requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin
                          initiatedByFrame:(WKFrameInfo *)frame
                                   decisionHandler:(void (^)(BOOL))handler {
    /* الموقع الوحيد المسموح طلب المايك: arabone.xyz */
    handler([origin.host isEqualToString:@"arabone.xyz"]);
}

/* لا نغلق التطبيق بالرجوع: الخروج الصحيح من مبدل التطبيقات */
- (BOOL)application:(UIApplication *)app
    openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return YES;
}

@end