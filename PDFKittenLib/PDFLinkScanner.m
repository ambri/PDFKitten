//
// Created by Adam Boardman on 06/12/2013.
// Copyright (c) 2013 Kotikan. All rights reserved.
//


#import "PDFLinkScanner.h"
#import "RenderingStateStack.h"
#import "PDFRenderingState.h"
#import "PDFFontCollection.h"

@interface PDFLinkScanner()
@property (nonatomic, strong) PDFFontCollection *fontCollection;
@property (weak, nonatomic, readonly) PDFRenderingState *renderingState;
@property (nonatomic, strong) RenderingStateStack *renderingStateStack;
@end

@implementation PDFLinkScanner {
    CGPDFPageRef pdfPage;
    NSMutableArray *links;
}

+ (PDFLinkScanner *)scannerWithPage:(CGPDFPageRef)page {
    return [[PDFLinkScanner alloc] initWithPage:page];
}

- (id)initWithPage:(CGPDFPageRef)page {
    if (self = [super init]) {
        pdfPage = page;
        links = [NSMutableArray array];
    }

    return self;
}

- (NSArray *)findHyperlinks {
    self.renderingStateStack = [RenderingStateStack stack];

    CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(pdfPage);
    CGPDFArrayRef annotsArray;

    if(!CGPDFDictionaryGetArray(pageDictionary, "Annots", &annotsArray)) {
        NSLog(@"No Annots found for page");
        return nil;
    }

    long annotsArrayCount = CGPDFArrayGetCount(annotsArray);
    NSLog(@"%ld annots found", annotsArrayCount);
    for (long j=annotsArrayCount-1; j >= 0; j--) {
        NSString* uri = nil;

        NSLog(@"%ld/%ld", j+1, annotsArrayCount);

        CGPDFObjectRef aDictObj;
        if(!CGPDFArrayGetObject(annotsArray, j, &aDictObj)) {
            NSLog(@"%@", @"can't get dictionary object");
            continue;
        }

        CGPDFDictionaryRef annotDict;
        if(!CGPDFObjectGetValue(aDictObj, kCGPDFObjectTypeDictionary, &annotDict)) {
            NSLog(@"%@", @"can't get annotDict");
            continue;
        }


        //------------
        CGPDFDictionaryRef aDict;
        if(CGPDFDictionaryGetDictionary(annotDict, "A", &aDict)) {
            CGPDFStringRef uriStringRef;
            if(CGPDFDictionaryGetString(aDict, "URI", &uriStringRef)) {
                char* uriString = (char *)CGPDFStringGetBytePtr(uriStringRef);
                uri = [NSString stringWithCString:uriString encoding:NSUTF8StringEncoding];
                [self findRectsInPage:pageDictionary annotDict:annotDict forUri:uri];
            }
        } else {
            continue;
        }
    }

    return links;
}

- (void)findRectsInPage:(CGPDFDictionaryRef)pageDictionary annotDict:(CGPDFDictionaryRef)annotDict forUri:(NSString*)uri {
    CGPDFArrayRef rectArray;
    if(!CGPDFDictionaryGetArray(annotDict, "Rect", &rectArray)) {
        NSLog(@"%@", @"can't get Rect");
    }

    long arrayCount = CGPDFArrayGetCount(rectArray);
    CGPDFReal coords[4];
    for (int k = 0; k < arrayCount; k++) {
        CGPDFObjectRef rectObj;
        if(!CGPDFArrayGetObject(rectArray, k, &rectObj)) {
            NSLog(@"%@", @"can't get rect data");
        }

        CGPDFReal coord;
        if(!CGPDFObjectGetValue(rectObj, kCGPDFObjectTypeReal, &coord)) {
            NSLog(@"%@", @"can't get coords");
        }

        coords[k] = coord;
    }

    CGRect frame = CGRectMake(coords[0], coords[1], coords[2]-coords[0], coords[3]-coords[1]);

    if (nil != uri) {
        NSValue *frameValue = [NSValue valueWithCGRect:frame];
        [links addObject:[NSDictionary dictionaryWithObjectsAndKeys:frameValue, @"frame", uri, @"targetUrl", nil]];
    }
}

@end