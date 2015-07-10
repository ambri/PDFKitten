#import "Type1Font.h"

@implementation Type1Font

- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if (self = [super initWithFontDictionary:dict])
	{
        CFStringRef stringRef = (__bridge CFStringRef)baseFont;

        gFontRef = CGFontCreateWithFontName(stringRef);
        tFontRef = CTFontCreateWithGraphicsFont(gFontRef,0,0,0);
        
        if (self.fontDescriptor == NULL) {
            self.fontDescriptor = [[PDFFontDescriptor alloc] initWithFontRef:gFontRef andFontName:baseFont];
        }
    }
	return self;
}

/* Width of the given character (CID) scaled to fontsize */
- (CGFloat)widthOfCharacter:(unichar)character withFontSize:(CGFloat)fontSize
{
    NSNumber *key = @(character);
    NSNumber *width = @(0);
    if (widths == NULL) {
        CGGlyph glyph;
        bool found = CTFontGetGlyphsForCharacters(tFontRef,&character,&glyph,1);
        int advance = 0;
        found = CGFontGetGlyphAdvances(gFontRef, &glyph, 1, &advance);
        width = @(advance);
    } else {
        width = (self.widths)[key];
    }
    return [width floatValue] * fontSize;
}

- (CGFloat)widthOfSpace
{
    CGFloat width = [super widthOfSpace];
    if (widths == NULL) {
        return width / ([self unitsPerEm] / [super unitsPerEm]);
    } else {
        return width;
    }
}

- (CGFloat)unitsPerEm {
    if (widths == NULL) {
        return CGFontGetUnitsPerEm(gFontRef);
    } else {
        return [super unitsPerEm];
    }
}

@end
