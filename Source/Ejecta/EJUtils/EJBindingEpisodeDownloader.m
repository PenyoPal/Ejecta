//
//  EJBindingURLFetcher.m
//  Ejecta
//
//  Created by James Cash on 24-10-12.
//
//

#import "EJBindingEpisodeDownloader.h"
#import "ZipArchive.h"

@interface EJBindingEpisodeDownloader ()
{
    BOOL _downloadImages;
    NSInteger _assetSize;
    NSData *_episodeContent;
    NSData *_episodeImages;
}

@end

@implementation EJBindingEpisodeDownloader

#pragma mark - Lifecycle
- (id)initWithContext:(JSContextRef)ctxp
                 argc:(size_t)argc
                 argv:(const JSValueRef [])argv
{
    if (self =  [super initWithContext:ctxp argc:argc argv:argv]) {
		errorCb = successCb = NULL;
        _downloadImages = NO;
        _assetSize = 0;
    }
    return self;
}

- (void)cancel
{
	JSContextRef gctx = scriptView.jsGlobalContext;
	if (errorCb) {
		JSValueUnprotect(gctx, errorCb);
		errorCb = NULL;
	}
	if (successCb) {
		JSValueUnprotect(gctx, successCb);
		successCb = NULL;
	}
	if (saveToPath) {
		[saveToPath release];
	}
}

#pragma mark - Downloading content
- (void)connectionFailed
{
    if( errorCb ) {
        JSContextRef gctx = scriptView.jsGlobalContext;
        JSValueRef params[] = { };
        [scriptView invokeCallback:errorCb thisObject:NULL argc:0 argv:params];
        JSValueUnprotect(gctx, errorCb);
		JSValueUnprotect(gctx, successCb);
		errorCb = successCb = NULL;
    }
}

- (BOOL)extractZipFrom:(NSData *)data toPath:(NSString *)path
{
	NSURL *fileURL = [NSURL fileURLWithPathComponents:
					  [NSArray arrayWithObjects:NSHomeDirectory(),
					   @"Library", path, nil]];

	NSLog(@"Downloaded data, saving to %@", fileURL);
	BOOL isDir = NO;
	if (![[NSFileManager defaultManager]
		  fileExistsAtPath:[fileURL URLByDeletingLastPathComponent].path
		  isDirectory:&isDir]) {
		NSLog(@"Need to create directory to download to");
		NSError *err = nil;
		[[NSFileManager defaultManager]
		 createDirectoryAtURL:[fileURL URLByDeletingLastPathComponent]
		 withIntermediateDirectories:YES attributes:nil error:&err];
		if (err) {
			NSLog(@"Failed to create directory! %@", err.localizedDescription);
			return NO;
		}
	}
	NSError *err = nil;
	[data writeToURL:fileURL options:NSDataWritingAtomic error:&err];
	if (err) {
		NSLog(@"Error writing data out: %@", err.localizedDescription);
		return NO;
	} else {
        // Extract episode zip
        ZipArchive *unzipper = [[ZipArchive alloc] init];
        [unzipper UnzipOpenFile:[fileURL path]];
        if ([unzipper UnzipFileTo:[[fileURL URLByDeletingLastPathComponent] path] overWrite:YES]) {
            NSLog(@"Unzipped content");
            return YES;
        } else {
            NSLog(@"Error unzipping download");
            return NO;
        }
	}
}

- (void)downloadSuccess
{
    NSURL *fileURL = [NSURL fileURLWithPathComponents:
					  [NSArray arrayWithObjects:NSHomeDirectory(),
					   @"Library", saveToPath, nil]];
    NSError *err = nil;
    NSURL *episodeJsonURL = [[fileURL URLByDeletingPathExtension] URLByAppendingPathComponent:@"episode.json"];
    NSString *episodeJson = [NSString stringWithContentsOfURL:episodeJsonURL encoding:NSUTF8StringEncoding error:&err];
    if (err || !episodeJson) {
        NSLog(@"Error getting JSON: %@ (%ul characters)", err, episodeJson.length);
        if (errorCb) {
            JSValueRef params[] = { };
            [scriptView invokeCallback:errorCb
                                  thisObject:NULL argc:0 argv:params];
        }
    } else if (successCb) {
        JSValueRef succParams[] = { NSStringToJSValue(scriptView.jsGlobalContext, episodeJson) };
        [scriptView invokeCallback:successCb thisObject:NULL argc:1 argv:succParams];
    }
    JSContextRef gctx = scriptView.jsGlobalContext;
    JSValueUnprotect(gctx, successCb);
    JSValueUnprotect(gctx, errorCb);
}

#pragma mark - EJBinding
EJ_BIND_FUNCTION(downloadEpisodeResources, ctx, argc, argv) {
    if (argc < 2) return NULL;

	[self cancel];

    NSURL *remoteUrl = [NSURL URLWithString:JSValueToNSString(ctx, argv[0])];
	saveToPath = [JSValueToNSString(ctx, argv[1]) retain];
	if( argc > 2 && JSValueIsObject(ctx, argv[2]) ) {
		successCb = JSValueToObject(ctx, argv[2], NULL);
        JSValueProtect(ctx, successCb);
    }
	if( argc > 3 && JSValueIsObject(ctx, argv[3]) ) {
		errorCb = JSValueToObject(ctx, argv[3], NULL);
        JSValueProtect(ctx, errorCb);
	}

    __block BOOL contentFailed = NO, imagesFailed = NO;

    dispatch_group_t group = dispatch_group_create();
    NSURLRequest *contentReq = [NSURLRequest requestWithURL:remoteUrl
                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:60.0];
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);

    dispatch_group_async(group, queue, ^{
        NSURLResponse *response; NSError *connectionError = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:contentReq
                                             returningResponse:&response
                                                         error:&connectionError];
        if (connectionError) {
            NSLog(@"Error downloading content: %@", connectionError.localizedDescription);
            contentFailed = YES;
        } else {
            _episodeContent = [data retain];
        }
    });

    if (_downloadImages) {
        NSString *episodeFileName = [remoteUrl lastPathComponent];
        NSURL *imagesUrl = [[NSURL URLWithString:[NSString stringWithFormat:@"../images/%d/%@", _assetSize, episodeFileName]
                                  relativeToURL:remoteUrl] absoluteURL];
        NSURLRequest *imagesReq = [NSURLRequest requestWithURL:imagesUrl
                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:60.0];
        dispatch_group_async(group, queue, ^{
            NSURLResponse *response; NSError *connectionError = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:imagesReq
                                                 returningResponse:&response
                                                             error:&connectionError];
            if (connectionError) {
                imagesFailed = YES;
            } else {
                _episodeImages = [data retain];
            }
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (contentFailed || imagesFailed) {
            NSLog(@"Download failed: content = %d, images = %d", contentFailed, imagesFailed);
            [self connectionFailed];
        } else {
            BOOL contentOk = [self extractZipFrom:_episodeContent toPath:saveToPath];
            BOOL imagesOk = YES;
            if (_downloadImages && contentOk) {
                NSString *imagesPath = [NSString stringWithFormat:@"assets/%@", [remoteUrl lastPathComponent]];
                imagesOk = [self extractZipFrom:_episodeImages toPath:imagesPath];
            }
            if (imagesOk && contentOk) {
                [self downloadSuccess];
            } else {
                NSLog(@"Unzipping failed: images = %d, content = %d", imagesOk, contentOk);
                [self connectionFailed];
            }
            [_episodeImages release];
            [_episodeContent release];
            // TODO: destroy queue & group?
        }
    });
    return NULL;
}

EJ_BIND_GET(getImages, ctx) { return JSValueMakeBoolean(ctx, _downloadImages); }

EJ_BIND_SET(getImages, ctx, value) {
    _downloadImages = JSValueToBoolean(ctx, value);
}

EJ_BIND_GET(assetSize, ctx) { return JSValueMakeNumber(ctx, _assetSize); }

EJ_BIND_SET(assetSize, ctx, value) {
    _assetSize = JSValueToNumberFast(ctx, value);
}

@end
