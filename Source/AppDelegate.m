
#import "AppDelegate.h"
#import "EJJavaScriptView.h"
@implementation AppDelegate
@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	// Optionally set the idle timer disabled, this prevents the device from sleep when
	// not being interacted with by touch. ie. games with motion control.
	application.idleTimerDisabled = NO;
	
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
        NSLog(@"Launched with url");
        [self handleOpenUrl:[launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]];
    }

    [self loadViewControllerWithScriptAtPath:@"index.js"];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"Open from url while running, from %@", sourceApplication);
    [self handleOpenUrl:url];
    return YES;
}

- (void)handleOpenUrl:(NSURL *)url
{
    NSLog(@"Handling url %@", url);
    // TODO
}

- (void)loadViewControllerWithScriptAtPath:(NSString *)path {
	// Release any previous ViewController
	window.frame = UIScreen.mainScreen.bounds;
	window.rootViewController = nil;
	
	EJAppViewController *vc = [[EJAppViewController alloc] initWithScriptAtPath:path];
	window.rootViewController = vc;
	[window makeKeyWindow];
	[vc release];
}



#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	window.rootViewController = nil;
	[window release];
    [super dealloc];
}


@end
