//
//  EJBindingColourizeFilter.m
//  Ejecta
//
//  Created by James Cash on 26-11-12.
//
//

#import "EJBindingColourizeFilter.h"
#import "EJBindingImageData.h"
#import "EJImageData.h"

struct pixel {
	GLubyte r;
	GLubyte g;
	GLubyte b;
};

struct pixel hsv2rgb(float hue, float sat, float val) {
	hue /= 360;
	int i = (int)(hue * 6);
	float f = hue * 6 - i;
	float p = val * (1 - sat);
	float q = val * (1 - f * sat);
	float t = val * (1 - (1 - f) * sat);
	int mod = i % 6;
	float r, g, b;
	switch (mod) {
		case 0:
			r = val;
			g = t;
			b = p;
			break;
		case 1:
			r = q;
			g = val;
			b = p;
			break;
		case 2:
			r = p;
			g = val;
			b = t;
			break;
		case 3:
			r = p;
			g = q;
			b = val;
			break;
		case 4:
			r = t;
			g = p;
			b = val;
			break;
		case 5:
			r = val;
			g = p;
			b = q;
			break;
	}
	return (struct pixel){(GLubyte)(r * 255), (GLubyte)(g * 255), (GLubyte)(b * 255)};
}

struct pixel blend2(struct pixel left, struct pixel right, float pos) {
	return (struct pixel){
		left.r * (1 - pos) + right.r * pos,
		left.g * (1 - pos) + right.g * pos,
		left.b * (1 - pos) + right.b * pos
	};
}

struct pixel blend3(struct pixel left, struct pixel main, struct pixel right, float pos) {
	if (pos < 0) {
		return blend2(left, main, pos + 1);
	}
	if (pos > 0) {
		return blend2(main, right, pos);
	}
	return main;
}

@implementation EJBindingColourizeFilter

- (void)filterImage:(EJImageData *)data
			withHue:(float)hue
		 saturation:(float)sat
		  lightness:(float)light
{
	GLubyte *pixels = data.pixels;
	struct pixel colour = blend2((struct pixel){128, 128, 128}, hsv2rgb(hue, 1, 0.5), sat);
	struct pixel black = { 0, 0, 0 },
				 white = { 255, 255, 255};
	float c1, c2;
	if (light >= 0) {
		c1 = -1, c2 = 1;
	} else {
		c1 = 0, c2 = 1;
	}
	float fact = 2 * (1 - light);
	float npixels = data.width * data.height * 4;
	for (int i = 0; i < npixels; i += 4) {
		GLubyte *r = &pixels[i], *g = &pixels[i+1], *b = &pixels[i+2];
		float pixelVal = (float)(MAX(*r, MAX(*g, *b))) / 255.0;
		struct pixel filtered = blend3(black, colour, white,
									   fact * (pixelVal + c1) + c2);
		*r = filtered.r, *g = filtered.g, *b = filtered.b;
	}
}

EJ_BIND_FUNCTION(colourizeImage, ctx, argc, argv) {
	if (argc < 4) {
		return NULL;
	}
	EJBindingImageData * jsImageData = (EJBindingImageData *)JSObjectGetPrivate((JSObjectRef)argv[0]);
	float
		hue = JSValueToNumberFast(ctx, argv[1]),
		sat = JSValueToNumberFast(ctx, argv[2]) / 100,
		light = JSValueToNumberFast(ctx, argv[3]) / 100;
	[self filterImage:jsImageData.imageData withHue:hue saturation:sat lightness:light];
	return NULL;
}

@end
