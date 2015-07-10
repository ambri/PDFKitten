#import "PDFStringDetector.h"

@implementation PDFStringDetector

+ (PDFStringDetector *)detectorWithKeyword:(NSString *)keyword delegate:(id<PDFStringDetectorDelegate>)delegate {
	PDFStringDetector *detector = [[PDFStringDetector alloc] initWithKeyword:keyword];
	detector.delegate = delegate;
	return detector;
}

- (id)initWithKeyword:(NSString *)string {
	if (self = [super init]) {
        keyword = [string lowercaseString];
        //self.unicodeContent = [NSMutableString string];
	}

	return self;
}

- (NSString *)appendString:(NSString *)inputString {
	NSString *lowercaseString = [inputString lowercaseString];
    int position = 0;
    if (lowercaseString) {
        //[unicodeContent appendString:lowercaseString];
    }

    while (position < inputString.length && [keyword length] > 0) {
		unichar inputCharacter = [inputString characterAtIndex:position];
		unichar actualCharacter = [lowercaseString characterAtIndex:position++];
        unichar expectedCharacter = 0;
        if ([keyword length] > 0 && keywordPosition < [keyword length]) {
            expectedCharacter = [keyword characterAtIndex:keywordPosition];
        }
        actualCharacter = [self verifyActualCharacter:actualCharacter withSimilarityTo:expectedCharacter];
        
        if (actualCharacter != expectedCharacter) {
            if (keywordPosition > 0) {
                // Read character again
                position--;
            }
			else if ([delegate respondsToSelector:@selector(detector:didScanCharacter:)]) {
				[delegate detector:self didScanCharacter:inputCharacter];
			}

            // Reset keyword position
            keywordPosition = 0;
            continue;
        }

        if (keywordPosition == 0 && [delegate respondsToSelector:@selector(detectorDidStartMatching:)]) {
            [delegate detectorDidStartMatching:self];
        }

        if ([delegate respondsToSelector:@selector(detector:didScanCharacter:)]) {
            [delegate detector:self didScanCharacter:inputCharacter];
        }

        if (++keywordPosition < keyword.length) {
            // Keep matching keyword
            continue;
        }

        // Reset keyword position
        keywordPosition = 0;
        if ([delegate respondsToSelector:@selector(detectorFoundString:)]) {
            [delegate detectorFoundString:self];
        }
    }

    return inputString;
}

- (unichar)verifyActualCharacter:(unichar)actualCharacter withSimilarityTo:(unichar)expectedCharacter {
    if (actualCharacter == [@"\u00ad" characterAtIndex:0] && expectedCharacter == '-') {
        actualCharacter = '-';
    }
    if (actualCharacter == [@"\u201c" characterAtIndex:0] && expectedCharacter == '"') {
        actualCharacter = '"';
    }
    if (actualCharacter == [@"\u201d" characterAtIndex:0] && expectedCharacter == '"') {
        actualCharacter = '"';
    }
    if (actualCharacter == [@"\u2018" characterAtIndex:0] && expectedCharacter == '\'') {
        actualCharacter = '\'';
    }
    if (actualCharacter == [@"\u2019" characterAtIndex:0] && expectedCharacter == '\'') {
        actualCharacter = '\'';
    }

    return actualCharacter;
}

- (void)setKeyword:(NSString *)kword {
    keyword = [kword lowercaseString];

    keywordPosition = 0;
}

- (void)reset {
    keywordPosition = 0;
}


@synthesize delegate; //, unicodeContent;
@end
