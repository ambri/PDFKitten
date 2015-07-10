#import "Page.h"
#import "PDFScanner.h"


@interface PDFContentView : PageContentView {
    CGPDFPageRef pdfPage;
    NSString *keyword;
}

#pragma mark

- (void)setPage:(CGPDFPageRef)page;

@property(nonatomic, strong) PDFScanner *scanner;
@property(nonatomic, strong) NSArray *selections;
@property(nonatomic, strong) NSArray *hyperlinks;

@end

#pragma mark

@interface PDFPage : Page {
}

#pragma mark

- (void)setPage:(CGPDFPageRef)page;

- (void)setSelections:(NSArray *)selections;

- (void)setHyperlinks:(NSArray *)hyperlinks;
@end
