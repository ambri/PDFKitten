#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>
#import "SimpleFont.h"

@interface Type1Font : SimpleFont {
    CGFontRef gFontRef;
    CTFontRef tFontRef;
}

@end
