#import "CompositeFont.h"

@implementation CompositeFont

/* Override with implementation for composite fonts */
- (void)setWidthsWithFontDictionary:(CGPDFDictionaryRef)dict
{
	CGPDFArrayRef widthsArray;
	if (CGPDFDictionaryGetArray(dict, "W", &widthsArray))
    {
        [self setWidthsWithArray:widthsArray];
    }

	CGPDFReal defaultWidthValue;
	if (CGPDFDictionaryGetNumber(dict, "DW", &defaultWidthValue))
	{
		self.defaultWidth = defaultWidthValue;
	}
}

- (void)setWidthsWithArray:(CGPDFArrayRef)widthsArray
{
    NSUInteger length = CGPDFArrayGetCount(widthsArray);
    int idx = 0;
    CGPDFObjectRef nextObject = nil;
    while (idx < length)
    {
        CGPDFInteger baseCid = 0;
        CGPDFArrayGetInteger(widthsArray, idx++, &baseCid);

        CGPDFObjectRef integerOrArray = nil;
        CGPDFInteger firstCharacter = 0;
		CGPDFArrayGetObject(widthsArray, idx++, &integerOrArray);
		if (CGPDFObjectGetType(integerOrArray) == kCGPDFObjectTypeInteger)
		{
            // [ first last width ]
			CGPDFInteger maxCid;
			CGPDFReal glyphWidth;
			CGPDFObjectGetValue(integerOrArray, kCGPDFObjectTypeInteger, &maxCid);
			CGPDFArrayGetNumber(widthsArray, idx++, &glyphWidth);
			[self setWidthsFrom:baseCid to:maxCid width:glyphWidth];

			// If the second item is an array, the sequence
			// defines widths on the form [ first list-of-widths ]
			CGPDFArrayRef characterWidths;
			if (!CGPDFObjectGetValue(nextObject, kCGPDFObjectTypeArray, &characterWidths)) break;
			NSUInteger widthsCount = CGPDFArrayGetCount(characterWidths);
			for (int index = 0; index < widthsCount ; index++)
			{
				CGPDFReal width;
				if (CGPDFArrayGetNumber(characterWidths, index, &width))
				{
					NSNumber *key = @(firstCharacter+index);
					NSNumber *val = @(width);
					widths[key] = val;
				}
			}
		}
		else
		{
            // [ first list-of-widths ]
			CGPDFArrayRef glyphWidths;
			CGPDFObjectGetValue(integerOrArray, kCGPDFObjectTypeArray, &glyphWidths);
            [self setWidthsWithBase:baseCid array:glyphWidths];
        }
	}
}

- (void)setWidthsFrom:(CGPDFInteger)cid to:(CGPDFInteger)maxCid width:(CGPDFInteger)width
{
    while (cid <= maxCid)
    {
        (self.widths)[@(cid++)] = @(width);
    }
}

- (void)setWidthsWithBase:(CGPDFInteger)base array:(CGPDFArrayRef)array
{
    NSInteger count = CGPDFArrayGetCount(array);
    CGPDFReal width;
    for (int index = 0; index < count ; index++)
    {
        if (CGPDFArrayGetNumber(array, index, &width))
        {
            (self.widths)[@(base+index)] = @(width);
        }
    }
}

- (CGFloat)widthOfCharacter:(unichar)characher withFontSize:(CGFloat)fontSize
{
	NSNumber *width = (self.widths)[@(characher - 30)];
	if (!width)
	{
		return self.defaultWidth * fontSize;
	}
	return [width floatValue] * fontSize;
}

@synthesize defaultWidth;
@end
