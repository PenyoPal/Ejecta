//
//  EJBindingCanvasPattern.m
//  Ejecta
//
//  Created by James Cash on 31-10-12.
//
//

#import "EJBindingCanvasPattern.h"
@class EJBindingImage;
@class EJBindingCanvas;

@interface EJBindingCanvasPattern ()
- (void)determineRepetitionType;
@end

@implementation EJBindingCanvasPattern

@synthesize texture;
@synthesize repetitionType;

- (id)initWithContext:(JSContextRef)ctxp object:(JSObjectRef)obj imageData:(NSObject *)img repetition:(NSString *)repetitionp
{
	if (self = [super initWithContext:ctxp object:obj argc:0 argv:NULL]) {
		if ([img respondsToSelector:@selector(path)]) {
			texture = [[EJTexture alloc]
					   initWithPath:[[EJApp instance]
									 pathForResource:[(EJBindingImage*)img path]]];
		} else if ([img respondsToSelector:@selector(texture)]) {
			texture = [[(EJBindingCanvas*)img texture] retain];
		} else {
			NSLog(@"Can't create pattern from the given image data");
		}
		repetition = repetitionp;
		[repetition retain];
		[self determineRepetitionType];
	}
	return self;
}

- (void)dealloc
{
	[texture release];
	[repetition release];
	[super dealloc];
}

- (void)determineRepetitionType
{
	if ([repetition isEqualToString:@"repeat-x"]) {
		repetitionType = REPEAT_X;
	} else if ([repetition isEqualToString:@"repeat-y"]) {
		repetitionType = REPEAT_Y;
	} else if ([repetition isEqualToString:@"no-repeat"]) {
		repetitionType = REPEAT_NONE;
	} else {
		repetitionType = REPEAT;
	}
}

@end
