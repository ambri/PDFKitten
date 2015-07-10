#import "PDFFontDescriptor.h"
#import "TrueTypeFont.h"
#import <CommonCrypto/CommonDigest.h>

const char *kAscentKey = "Ascent";
const char *kDescentKey = "Descent";
const char *kLeadingKey = "Leading";
const char *kCapHeightKey = "CapHeight";
const char *kXHeightKey = "XHeight";
const char *kAverageWidthKey = "AvgWidth";
const char *kMaxWidthKey = "MaxWidth";
const char *kMissingWidthKey = "MissingWidth";
const char *kFlagsKey = "Flags";
const char *kStemVKey = "StemV";
const char *kStemHKey = "StemH";
const char *kItalicAngleKey = "ItalicAngle";
const char *kFontNameKey = "FontName";
const char *kFontBBoxKey = "FontBBox";
const char *kFontFileKey = "FontFile";


@implementation PDFFontDescriptor

- (id)initWithFontRef:(CGFontRef)fontRef andFontName:(NSString*)font {
    if ((self = [super init])) {
        self.ascent = CGFontGetAscent(fontRef);
        self.descent = CGFontGetDescent(fontRef);
        self.leading = CGFontGetLeading(fontRef);
        self.capHeight = CGFontGetCapHeight(fontRef);
        self.xHeight = CGFontGetXHeight(fontRef);
        //self.averageWidth
        //self.maxWidth
        //self.missingWidth
        //self.flags
        //self.verticalStemWidth
        //self.horizontalStemWidth
        //self.italicAngle
        self.fontName = font;
    }
    return self;
}

- (id)initWithPDFDictionary:(CGPDFDictionaryRef)dict
{
	const char *type = nil;
	CGPDFDictionaryGetName(dict, kTypeKey, &type);
	if (!type || strcmp(type, kFontDescriptorKey) != 0)
	{
		// some editior may omit /FontDescriptor key
		// [self release]; return nil;
	}

	if ((self = [super init]))
	{
		CGPDFReal ascentValue = 0;
		CGPDFReal descentValue = 0;
		CGPDFReal leadingValue = 0;
		CGPDFReal capHeightValue = 0;
		CGPDFReal xHeightValue = 0;
		CGPDFReal averageWidthValue = 0;
		CGPDFReal maxWidthValue = 0;
		CGPDFReal missingWidthValue = 0;
		CGPDFInteger flagsValue = 0L;
		CGPDFReal stemV = 0;
		CGPDFReal stemH = 0;
		CGPDFReal italicAngleValue = 0;
		const char *fontNameString = nil;
		CGPDFArrayRef bboxValue = nil;

		CGPDFDictionaryGetNumber(dict, kAscentKey, &ascentValue);
        CGPDFDictionaryGetNumber(dict, kDescentKey, &descentValue);
        CGPDFDictionaryGetNumber(dict, kLeadingKey, &leadingValue);
		CGPDFDictionaryGetNumber(dict, kCapHeightKey, &capHeightValue);
		CGPDFDictionaryGetNumber(dict, kXHeightKey, &xHeightValue);
		CGPDFDictionaryGetNumber(dict, kAverageWidthKey, &averageWidthValue);
		CGPDFDictionaryGetNumber(dict, kMaxWidthKey, &maxWidthValue);
		CGPDFDictionaryGetNumber(dict, kMissingWidthKey, &missingWidthValue);
		CGPDFDictionaryGetInteger(dict, kFlagsKey, &flagsValue);
		CGPDFDictionaryGetNumber(dict, kStemVKey, &stemV);
        CGPDFDictionaryGetNumber(dict, kStemHKey, &stemH);
        CGPDFDictionaryGetNumber(dict, kItalicAngleKey, &italicAngleValue);
        CGPDFDictionaryGetName(dict, kFontNameKey, &fontNameString);
		CGPDFDictionaryGetArray(dict, kFontBBoxKey, &bboxValue);
        
        self.ascent = ascentValue;
        self.descent = descentValue;
        self.leading = leadingValue;
		self.capHeight = capHeightValue;
		self.xHeight = xHeightValue;
		self.averageWidth = averageWidthValue;
		self.maxWidth = maxWidthValue;
        self.missingWidth = missingWidthValue;
        self.flags = flagsValue;
        self.verticalStemWidth = stemV;
        self.horizontalStemWidth = stemH;
        self.italicAngle = italicAngleValue;
        self.fontName = @(fontNameString);

		if (CGPDFArrayGetCount(bboxValue) == 4)
		{
			CGPDFReal x = 0, y = 0, width = 0, height = 0;
			CGPDFArrayGetNumber(bboxValue, 0, &x);
			CGPDFArrayGetNumber(bboxValue, 1, &y);
			CGPDFArrayGetNumber(bboxValue, 2, &width);
			CGPDFArrayGetNumber(bboxValue, 3, &height);
			self.bounds = CGRectMake(x, y, width, height);
		}
		
		CGPDFStreamRef fontFileStream;
		if (CGPDFDictionaryGetStream(dict, kFontFileKey, &fontFileStream))
		{
			CGPDFDataFormat format;
			NSData *data = (NSData *) CFBridgingRelease(CGPDFStreamCopyData(fontFileStream, &format));
			/*
	 		NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
			path = [path stringByAppendingPathComponent:@"fontfile"];
			[data writeToFile:path atomically:YES];
			  */
			fontFile = [[FontFile alloc] initWithData:data];
		}

	}
	return self;
}

+ (void)parseFontFile:(NSData *)data
{
//	CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(text);
//	
//	CGPDFInteger cleartextLength, decryptedLength, fixedLength;
//	CGPDFInteger totalLength;
//	CGPDFDictionaryGetInteger(dict, "Length1", &cleartextLength);
//	CGPDFDictionaryGetInteger(dict, "Length2", &decryptedLength);
//	CGPDFDictionaryGetInteger(dict, "Length3", &fixedLength);
//	CGPDFDictionaryGetInteger(dict, "Length", &totalLength);
//	
//	NSLog(@"Lengths: %ld, %ld, %ld", cleartextLength, decryptedLength, fixedLength);
//	NSLog(@"Total: %ld", totalLength);
//	
//	CGPDFDataFormat format;
//	CFDataRef data = CGPDFStreamCopyData(text, &format);
//	const uint8_t *ptr = CFDataGetBytePtr(data);
//	size_t length = CFDataGetLength(data);
//	NSData *fontData = [NSData dataWithBytes:ptr length:length];
//
//	size_t digestStringLength = CC_MD5_DIGEST_LENGTH * sizeof(unsigned char);
//	unsigned char *digest = malloc(digestStringLength);
//	bzero(digest, digestStringLength);
//	CC_MD5(data, length, digest);

	// Get first header
	
}

/* True if a font is symbolic */
- (BOOL)isSymbolic
{
	return ((self.flags & FontSymbolic) > 0) && ((self.flags & FontNonSymbolic) == 0);
}

#pragma mark Memory Management


@synthesize ascent, descent, bounds, leading, capHeight, averageWidth, maxWidth, missingWidth, xHeight, flags, verticalStemWidth, horizontalStemWidth, italicAngle, fontName;
@synthesize fontFile;
@end
