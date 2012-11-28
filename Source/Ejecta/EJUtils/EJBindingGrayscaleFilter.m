//
//  EJBindingGrayscaleFilter.m
//  Ejecta
//
//  Created by James Cash on 27-11-12.
//
//

#import "EJBindingGrayscaleFilter.h"
#import "EJBindingImageData.h"
#import "EJImageData.h"

@implementation EJBindingGrayscaleFilter

- (void)filterImage:(EJImageData *)data
{
	GLubyte *pixels = data.pixels;
	int nBytes = data.height * data.width * 4;
	for (int i = 0; i < nBytes; i += 4) {
		int v = (int)(0.2126 * (float)pixels[i] + 0.7152 * (float)pixels[i+1] + 0.0722 * (float)pixels[i+2]);
		pixels[i] = pixels[i+1] = pixels[i+2] = (GLubyte)v;
	}
}

EJ_BIND_FUNCTION(grayscaleImage, ctx, argc, argv) {
	if (argc < 1) {
		return NULL;
	}
	EJBindingImageData * jsImageData = (EJBindingImageData *)JSObjectGetPrivate((JSObjectRef)argv[0]);
	[self filterImage:jsImageData.imageData];
	return NULL;
}

@end
