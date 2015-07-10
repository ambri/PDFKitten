//
//  PDFKitten.m
//  PDFKitten
//

#import "PDFKitten.h"
#import "PDFScanner.h"
#import "PDFSelection.h"
#import "PDFLinkScanner.h"


@implementation PDFKitten {
    CGPDFDocumentRef document;
    NSMutableArray *selections;
    NSMutableDictionary *pagedHyperlinks;
    NSThread *searchThread;
    NSThread *hyperlinkFindThread;
    NSInteger currentPage;
    NSInteger startPage;
    BOOL currentScanningInProgress;
    NSString *searchKeyword;
    BOOL requestRestartSearch;
    NSInteger hyperlinkFindPage;
    BOOL requestNewPageHyperlinkFind;
}

+ (PDFKitten *)loadDocument:(NSURL *)url {
    PDFKitten *pdfKitten = [[PDFKitten alloc] initWithUrl:url];
    return pdfKitten;
}

- (id)initWithUrl:(NSURL *)url {
    document = CGPDFDocumentCreateWithURL((CFURLRef)url);
    currentPage = 0;
    pagedHyperlinks = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)dealloc {
    CGPDFDocumentRelease(document);
}

- (NSInteger)numberOfPages {
    return CGPDFDocumentGetNumberOfPages(document);
}

- (CGPDFPageRef)getPage:(NSInteger)number {
    return CGPDFDocumentGetPage(document, (size_t) (number + 1)); // PDF document page numbers are 1-based
}

- (void)startSearchFromPage:(NSInteger)pageNumber withKeyword:(NSString*)keyword {
    if (currentScanningInProgress) {
        startPage = pageNumber;
        searchKeyword = keyword;
        requestRestartSearch = YES;
        return;
    }

    [self removeAndResetSelections];

    [searchThread cancel];

    currentPage = pageNumber;
    searchKeyword = keyword;

    searchThread = [[NSThread alloc] initWithTarget:self selector:@selector(scanDocumentInBackground) object:nil];
    currentScanningInProgress = YES;
    [searchThread start];
}

- (void)stopSearch {
    [searchThread cancel];
    selections = nil;
}

#define CONTEXT_LENGTH 14

- (void)scanDocumentInBackground {

    startPage = currentPage;
    BOOL searchFinished = NO;
    while (!searchFinished && ![[NSThread currentThread] isCancelled]) {

        CGPDFPageRef page = [self getPage:currentPage];
        PDFScanner *pdfScanner = [PDFScanner scannerWithPage:page];
        NSArray *pageSelections = [pdfScanner select:searchKeyword];

        for (PDFSelection *selection in pageSelections) {
            NSUInteger loc = MAX(0, ((int)selection.foundLocation) - CONTEXT_LENGTH);
            NSUInteger len = MIN((selection.foundLocation - loc) + [searchKeyword length] + CONTEXT_LENGTH,
                                 pdfScanner.content.length - loc);
            
            NSRange contextRange = NSMakeRange(loc, len);
            selection.searchContext = [pdfScanner.content substringWithRange:contextRange];
        }

        if (requestRestartSearch) {
            [self backgroundResetSearch];
        } else {
            [self backgroundShowSelections:pageSelections];
            searchFinished = [self backgroundUpdatePageCheckIfFinished:searchFinished];
        }
    }
    currentScanningInProgress = NO;
}

- (BOOL)backgroundUpdatePageCheckIfFinished:(BOOL)searchFinished {
    currentPage++;
    if (currentPage >= [self numberOfPages]) {
        currentPage = 0;
    }
    if (currentPage == startPage) {
        searchFinished = YES;
    }
    return searchFinished;
}

- (void)backgroundShowSelections:(NSArray *)pageSelections {
    if ([pageSelections count] > 0) {
        [selections addObjectsFromArray:pageSelections];
    }
    [_delegate scanResultsUpdated:selections];
}

- (void)backgroundResetSearch {
    requestRestartSearch = NO;
    currentPage = startPage;
    [self removeAndResetSelections];
}

- (void)removeAndResetSelections {
    [selections removeAllObjects];
    if (selections == nil) {
        selections = [[NSMutableArray alloc] init];
    }
}

- (BOOL)scanInProgress {
    return currentScanningInProgress;
}

- (NSArray*)getSelections {
    return selections;
}

- (void)findHyperlinksForPage:(NSInteger)page {
    NSArray *hyperlinks = [pagedHyperlinks objectForKey:@(page)];
    if ([hyperlinks count] > 0) {
        [_delegate hyperlinks:pagedHyperlinks];
    }
    if (hyperlinks != nil) {
        return;
    }
    if (_hyperlinkFindInProgress) {
        hyperlinkFindPage = page;
        requestNewPageHyperlinkFind = YES;
        return;
    }

    [hyperlinkFindThread cancel];

    hyperlinkFindPage = page;
    
    hyperlinkFindThread = [[NSThread alloc] initWithTarget:self selector:@selector(hyperlinkFindInBackground) object:nil];
    _hyperlinkFindInProgress = YES;
    [hyperlinkFindThread start];
}

- (void)hyperlinkFindInBackground {
    NSInteger findingOnPage = hyperlinkFindPage;
    BOOL findFinished = NO;
    while (!findFinished && ![[NSThread currentThread] isCancelled]) {

        CGPDFPageRef pCGPDFPage = [self getPage:findingOnPage];
        PDFLinkScanner *pdfLinkScanner = [PDFLinkScanner scannerWithPage:pCGPDFPage];
        NSArray *links = [pdfLinkScanner findHyperlinks];
        if (links) {
            [pagedHyperlinks setObject:links forKey:@(findingOnPage)];
            [_delegate hyperlinks:pagedHyperlinks];
        } else {
            requestNewPageHyperlinkFind = NO;
        }
        if (requestNewPageHyperlinkFind) {
            requestNewPageHyperlinkFind = NO;
            findingOnPage = hyperlinkFindPage;
        } else {
            findFinished = YES;
        }
    }
    _hyperlinkFindInProgress = NO;
}

- (NSArray *)getHyperlinksForPage:(int)page {
    return [pagedHyperlinks objectForKey:@(page)];
}

@end
