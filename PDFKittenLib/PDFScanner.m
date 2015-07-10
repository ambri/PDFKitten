#import "PDFScanner.h"
#import "PDFStringDetector.h"
#import "PDFFontCollection.h"
#import "PDFRenderingState.h"
#import "PDFSelection.h"
#import "RenderingStateStack.h"
#import "SimpleFont.h"

static void setHorizontalScale(CGPDFScannerRef pdfScanner, void *info);
static void setTextLeading(CGPDFScannerRef pdfScanner, void *info);
static void setFont(CGPDFScannerRef pdfScanner, void *info);
static void setTextRise(CGPDFScannerRef pdfScanner, void *info);
static void setCharacterSpacing(CGPDFScannerRef pdfScanner, void *info);
static void setWordSpacing(CGPDFScannerRef pdfScanner, void *info);
static void newLine(CGPDFScannerRef pdfScanner, void *info);
static void newLineWithLeading(CGPDFScannerRef pdfScanner, void *info);
static void newLineSetLeading(CGPDFScannerRef pdfScanner, void *info);
static void newParagraph(CGPDFScannerRef pdfScanner, void *info);
static void setTextMatrix(CGPDFScannerRef pdfScanner, void *info);
static void printString(CGPDFScannerRef pdfScanner, void *info);
static void printStringNewLine(CGPDFScannerRef scanner, void *info);
static void printStringNewLineSetSpacing(CGPDFScannerRef scanner, void *info);
static void printStringsAndSpaces(CGPDFScannerRef pdfScanner, void *info);
static void pushRenderingState(CGPDFScannerRef pdfScanner, void *info);
static void popRenderingState(CGPDFScannerRef pdfScanner, void *info);
static void applyTransformation(CGPDFScannerRef pdfScanner, void *info);

@interface PDFStringDetectorBBox : PDFStringDetector
@property (readonly, nonatomic) CGRect result;
@end

@interface PDFScanner() <PDFStringDetectorDelegate>
@property (nonatomic, readonly) PDFRenderingState *renderingState;
@property (nonatomic, retain) RenderingStateStack *renderingStateStack;
@property (nonatomic, retain) PDFStringDetector *stringDetector;
@end

@implementation PDFScanner  {
    
	CGPDFPageRef pdfPage;
    PDFSelection *possibleSelection;
    
	//NSMutableArray *selections;
	//StringDetector *stringDetector;
	//FontCollection *fontCollection;
	//RenderingStateStack *renderingStateStack;
	//NSMutableString *content;
}

+ (PDFScanner *)scannerWithPage:(CGPDFPageRef)page {
	return [[[PDFScanner alloc] initWithPage:page] autorelease];
}

- (id)initWithPage:(CGPDFPageRef)page {
	if (self = [super init]) {
		pdfPage = page;
		self.fontCollection = [self fontCollectionWithPage:pdfPage];
		self.selections = [NSMutableArray array];
	}
	
	return self;
}

- (NSArray *)select:(NSString *)keyword {
    self.content = [NSMutableString string];
	self.stringDetector = [PDFStringDetector detectorWithKeyword:keyword delegate:self];
	[self.selections removeAllObjects];
    self.renderingStateStack = [RenderingStateStack stack];
    
 	CGPDFOperatorTableRef operatorTable = [self newOperatorTable];
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(pdfPage);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, self);
	CGPDFScannerScan(scanner);
	
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(operatorTable);
    
    //NSLog(@"found %d for %@", self.selections.count, keyword);
    //NSLog(@"content:%@", self.content);
	
    self.stringDetector.delegate = nil;
    self.stringDetector = nil;
    
	return self.selections;
}

- (CGRect)boundingBox
{
    self.content = nil;
	[self.selections removeAllObjects];
    
    PDFStringDetectorBBox *pdfBBOX = [[PDFStringDetectorBBox alloc] initWithKeyword:nil];
    
    self.stringDetector = pdfBBOX;
	self.stringDetector.delegate = self;
	
    self.renderingStateStack = [RenderingStateStack stack];
        
 	CGPDFOperatorTableRef operatorTable = [self newOperatorTable];
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(pdfPage);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, operatorTable, self);
	CGPDFScannerScan(scanner);
	
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(operatorTable);
    
    self.stringDetector.delegate = nil;
    self.stringDetector = nil;
        
    const CGRect result = pdfBBOX.result;
    [pdfBBOX release];
    
    return result;
}

- (CGPDFOperatorTableRef)newOperatorTable {
	CGPDFOperatorTableRef operatorTable = CGPDFOperatorTableCreate();

	// Text-showing operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tj", printString);
	CGPDFOperatorTableSetCallback(operatorTable, "\'", printStringNewLine);
	CGPDFOperatorTableSetCallback(operatorTable, "\"", printStringNewLineSetSpacing);
	CGPDFOperatorTableSetCallback(operatorTable, "TJ", printStringsAndSpaces);
	
	// Text-positioning operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tm", setTextMatrix);
	CGPDFOperatorTableSetCallback(operatorTable, "Td", newLineWithLeading);
	CGPDFOperatorTableSetCallback(operatorTable, "TD", newLineSetLeading);
	CGPDFOperatorTableSetCallback(operatorTable, "T*", newLine);
	
	// Text state operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tw", setWordSpacing);
	CGPDFOperatorTableSetCallback(operatorTable, "Tc", setCharacterSpacing);
	CGPDFOperatorTableSetCallback(operatorTable, "TL", setTextLeading);
	CGPDFOperatorTableSetCallback(operatorTable, "Tz", setHorizontalScale);
	CGPDFOperatorTableSetCallback(operatorTable, "Ts", setTextRise);
	CGPDFOperatorTableSetCallback(operatorTable, "Tf", setFont);
	
	// Graphics state operators
	CGPDFOperatorTableSetCallback(operatorTable, "cm", applyTransformation);
	CGPDFOperatorTableSetCallback(operatorTable, "q", pushRenderingState);
	CGPDFOperatorTableSetCallback(operatorTable, "Q", popRenderingState);
	
	CGPDFOperatorTableSetCallback(operatorTable, "BT", newParagraph);
	
	return operatorTable;
}

/* Create a font dictionary given a PDF page */
- (PDFFontCollection *)fontCollectionWithPage:(CGPDFPageRef)page {
	CGPDFDictionaryRef dict = CGPDFPageGetDictionary(page);
	if (!dict) 	{
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing");
		return nil;
	}
	
	CGPDFDictionaryRef resources;
	if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources)) {
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing Resources dictionary");
		return nil;
	}

	CGPDFDictionaryRef fonts;
	if (!CGPDFDictionaryGetDictionary(resources, "Font", &fonts)) {
		return nil;
	}

	PDFFontCollection *collection = [[PDFFontCollection alloc] initWithFontDictionary:fonts];
	return [collection autorelease];
}

- (void)detector:(PDFStringDetector *)detector didScanCharacter:(unichar)character {
    
    PDFFont *font = self.renderingState.font;
    NSUInteger cid = character;
    
    if (!font.encoding && font.toUnicode) {
        
        cid = [font.toUnicode cidCharacter:character];
        if (cid == NSNotFound && character != 0x20) {
            
            NSLog(@"warning: no unicode cid for char %x", character);
            cid = character;
        }
        
    } else if ([font isKindOfClass:[SimpleFont class]] &&
               ((SimpleFont *)font).encodingDifferences) {
        
        cid = [((SimpleFont *)font).encodingDifferences cidCharacter:character
                                                        withEncoding:font.encoding];
        
        if (cid == NSNotFound && character != 0x20) {
            
            NSLog(@"warning: no encoding cid for char %x", character);
            cid = character;
        }
        
    } else {
        
        cid = (unichar)character;
    }
    
    CGFloat width = [font widthOfCharacter:cid withFontSize:self.renderingState.fontSize];
    width /= 1000;
    width += self.renderingState.characterSpacing;
    if (character == 32) {
        width += self.renderingState.wordSpacing;
    }
    
    if (!width && character == 0x20) {
        width = self.renderingState.widthOfSpace / 1000.f;
    }
    
	[self.renderingState translateTextPosition:CGSizeMake(width, 0)];
}

- (void)detectorDidStartMatching:(PDFStringDetector *)detector {
    
    if (possibleSelection) {
        
        [possibleSelection release];
        possibleSelection = nil;
    }
    
    possibleSelection = [[PDFSelection selectionWithState:self.renderingState] retain];
    possibleSelection.foundLocation = self.content.length;
}

- (void)detectorFoundString:(PDFStringDetector *)detector {
    if (possibleSelection) {
	    possibleSelection.finalState = self.renderingState;
        [self.selections addObject:possibleSelection];
        [possibleSelection release];
        possibleSelection = nil;
    }
}

- (PDFRenderingState *)renderingState {
	return [self.renderingStateStack topRenderingState];
}

- (void)dealloc {
    [possibleSelection release];
	[fontCollection release];
	[selections release];
	[renderingStateStack release];
	[stringDetector release];
	[content release];
	[super dealloc];
}

@synthesize stringDetector, fontCollection, renderingStateStack, content, selections, renderingState;
@end

///


static BOOL isSpace(float width, PDFScanner *scanner) {
	return abs(width) >= scanner.renderingState.widthOfSpace;
}

void didScanSpace(float value, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
    float width = [scanner.renderingState convertToUserSpace:value];
    [scanner.renderingState translateTextPosition:CGSizeMake(-width, 0)];
    if (isSpace(value, scanner)) {
        
        PDFStringDetector *stringDetector = scanner.stringDetector;
        [stringDetector appendString:@" "];
        [scanner.content appendString:@" "];
        //[scanner.stringDetector reset];
    }
}

void didScanString(CGPDFStringRef pdfString, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	PDFStringDetector *stringDetector = scanner.stringDetector;
	PDFFont *font = scanner.renderingState.font;
    NSString *string =  [font stringWithPDFString:pdfString];
    if (string) {
        [stringDetector appendString:string];
        [scanner.content appendString:string];
    }
}

void didScanNewLine(CGPDFScannerRef pdfScanner, PDFScanner *scanner, BOOL persistLeading) {
	CGPDFReal tx, ty;
	CGPDFScannerPopNumber(pdfScanner, &ty);
	CGPDFScannerPopNumber(pdfScanner, &tx);
	[scanner.renderingState newLineWithLeading:-ty indent:tx save:persistLeading];
}

CGPDFStringRef getString(CGPDFScannerRef pdfScanner) {
	CGPDFStringRef pdfString;
	CGPDFScannerPopString(pdfScanner, &pdfString);
	return pdfString;
}

CGPDFReal getNumber(CGPDFScannerRef pdfScanner) {
	CGPDFReal value;
	CGPDFScannerPopNumber(pdfScanner, &value);
	return value;
}

CGPDFArrayRef getArray(CGPDFScannerRef pdfScanner) {
	CGPDFArrayRef pdfArray;
	CGPDFScannerPopArray(pdfScanner, &pdfArray);
	return pdfArray;
}

CGPDFObjectRef getObject(CGPDFArrayRef pdfArray, int index) {
	CGPDFObjectRef pdfObject;
	CGPDFArrayGetObject(pdfArray, index, &pdfObject);
	return pdfObject;
}

CGPDFStringRef getStringValue(CGPDFObjectRef pdfObject) {
	CGPDFStringRef string;
	CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeString, &string);
	return string;
}

float getNumericalValue(CGPDFObjectRef pdfObject, CGPDFObjectType type) {
	if (type == kCGPDFObjectTypeReal) {
		CGPDFReal tx;
		CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeReal, &tx);
		return tx;
	}
	else if (type == kCGPDFObjectTypeInteger) {
		CGPDFInteger tx;
		CGPDFObjectGetValue(pdfObject, kCGPDFObjectTypeInteger, &tx);
		return tx;
	}
    
	return 0;
}

CGAffineTransform getTransform(CGPDFScannerRef pdfScanner) {
	CGAffineTransform transform;
	transform.ty = getNumber(pdfScanner);
	transform.tx = getNumber(pdfScanner);
	transform.d = getNumber(pdfScanner);
	transform.c = getNumber(pdfScanner);
	transform.b = getNumber(pdfScanner);
	transform.a = getNumber(pdfScanner);
	return transform;
}

#pragma mark Text parameters

static void setHorizontalScale(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState setHorizontalScaling:getNumber(pdfScanner)];
}

static void setTextLeading(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState setLeadning:getNumber(pdfScanner)];
}

static void setFont(CGPDFScannerRef pdfScanner, void *info) {
	CGPDFReal fontSize;
	const char *fontName;
	CGPDFScannerPopNumber(pdfScanner, &fontSize);
	CGPDFScannerPopName(pdfScanner, &fontName);
	
	PDFScanner *scanner = (PDFScanner *) info;
	PDFRenderingState *state = scanner.renderingState;
	PDFFont *font = [scanner.fontCollection fontNamed:[NSString stringWithUTF8String:fontName]];
	[state setFont:font];
	[state setFontSize:fontSize];
}

static void setTextRise(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState setTextRise:getNumber(pdfScanner)];
}

static void setCharacterSpacing(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState setCharacterSpacing:getNumber(pdfScanner)];
}

static void setWordSpacing(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState setWordSpacing:getNumber(pdfScanner)];
}


#pragma mark Set position

static void newLine(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState newLine];
}

static void newLineWithLeading(CGPDFScannerRef pdfScanner, void *info) {
	didScanNewLine(pdfScanner, (PDFScanner *) info, NO);
}

static void newLineSetLeading(CGPDFScannerRef pdfScanner, void *info) {
	didScanNewLine(pdfScanner, (PDFScanner *) info, YES);
}

static void newParagraph(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState setTextMatrix:CGAffineTransformIdentity replaceLineMatrix:YES];
}

static void setTextMatrix(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingState setTextMatrix:getTransform(pdfScanner) replaceLineMatrix:YES];
}


#pragma mark Print strings

static void printString(CGPDFScannerRef pdfScanner, void *info) {
	didScanString(getString(pdfScanner), info);
}

static void printStringNewLine(CGPDFScannerRef pdfScanner, void *info) {
	newLine(pdfScanner, info);
	printString(pdfScanner, info);
    
    PDFScanner *scanner = (PDFScanner *) info;
    PDFStringDetector *stringDetector = scanner.stringDetector;
    [stringDetector appendString:@"\n"];
    [scanner.content appendString:@"\n"];
    [scanner.stringDetector reset];
}

static void printStringNewLineSetSpacing(CGPDFScannerRef scanner, void *info) {
	setWordSpacing(scanner, info);
	setCharacterSpacing(scanner, info);
	printStringNewLine(scanner, info);
}

static void printStringsAndSpaces(CGPDFScannerRef pdfScanner, void *info) {
	CGPDFArrayRef array = getArray(pdfScanner);
	for (int i = 0; i < CGPDFArrayGetCount(array); i++) {
		CGPDFObjectRef pdfObject = getObject(array, i);
		CGPDFObjectType valueType = CGPDFObjectGetType(pdfObject);
        
		if (valueType == kCGPDFObjectTypeString) {
			didScanString(getStringValue(pdfObject), info);
		}
		else {
			didScanSpace(getNumericalValue(pdfObject, valueType), info);
		}
	}
    
    PDFScanner *scanner = (PDFScanner *) info;
    PDFStringDetector *stringDetector = scanner.stringDetector;
    [stringDetector appendString:@" "];
    [scanner.content appendString:@" "];
}


#pragma mark Graphics state operators

static void pushRenderingState(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	PDFRenderingState *state = [scanner.renderingState copy];
	[scanner.renderingStateStack pushRenderingState:state];
	[state release];
}

static void popRenderingState(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	[scanner.renderingStateStack popRenderingState];
}

/* Update CTM */
static void applyTransformation(CGPDFScannerRef pdfScanner, void *info) {
	PDFScanner *scanner = (PDFScanner *) info;
	PDFRenderingState *state = scanner.renderingState;
	state.ctm = CGAffineTransformConcat(getTransform(pdfScanner), state.ctm);
}


#pragma mark - PDFStringDetectorBBox

@implementation PDFStringDetectorBBox {
    
    BOOL _resultIsValid;
}

- (NSString *)appendString:(NSString *)inputString
{    
    PDFScanner *scanner = delegate;
    PDFSelection *selection = [PDFSelection selectionWithState:scanner.renderingState];
    
    int position = 0;
    while (position < inputString.length) {
        
		unichar inputCharacter = [inputString characterAtIndex:position];
		[delegate detector:self didScanCharacter:inputCharacter];
        ++position;        
    }
    
    selection.finalState = scanner.renderingState;
    const CGRect bbox = CGRectApplyAffineTransform(selection.frame, selection.transform);
    if (_resultIsValid) {
        
        _result = CGRectUnion(bbox, _result);
        
    } else {
        
        _resultIsValid = YES;
        _result = bbox;
    }
        
    return inputString;
}
@end
