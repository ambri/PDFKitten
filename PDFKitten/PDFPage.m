#import "PDFPage.h"
#import "PDFSelection.h"
#import <QuartzCore/QuartzCore.h>

@implementation PDFContentView

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor whiteColor];

        CATiledLayer *tiledLayer = (CATiledLayer *) [self layer];
        tiledLayer.frame = CGRectMake(0, 0, 100, 100);
        [tiledLayer setTileSize:CGSizeMake(1024, 1024)];
        [tiledLayer setLevelsOfDetail:4];
        [tiledLayer setLevelsOfDetailBias:4];
    }
    return self;
}

+ (Class)layerClass {
    return [CATiledLayer class];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGContextSetFillColorWithColor(ctx, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(ctx, layer.bounds);

    // Flip the coordinate system
    CGContextTranslateCTM(ctx, 0.0, layer.bounds.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);

    // Transform coordinate system to match PDF
    CGAffineTransform transform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, layer.bounds, 0, YES);
    CGContextConcatCTM(ctx, transform);

    CGContextDrawPDFPage(ctx, pdfPage);

    if (self.selections) {
        CGContextSetFillColorWithColor(ctx, [[UIColor yellowColor] CGColor]);
        CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
        for (PDFSelection *s in self.selections) {
            CGContextSaveGState(ctx);
            CGContextConcatCTM(ctx, s.transform);
            CGContextFillRect(ctx, s.frame);
            CGContextRestoreGState(ctx);
        }
    }
}

#pragma mark PDF drawing

/* Draw the PDFPage to the content view */
- (void)drawRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(ctx, [[UIColor redColor] CGColor]);
    CGContextFillRect(ctx, rect);
}

/* Sets the current PDFPage object */
- (void)setPage:(CGPDFPageRef)page {
    CGPDFPageRelease(pdfPage);
    pdfPage = CGPDFPageRetain(page);
}

- (void)dealloc {
    CGPDFPageRelease(pdfPage);
}

@synthesize selections;

@end

#pragma mark -

@implementation PDFPage {
    CGPDFPageRef pageRef;
}

#pragma mark -

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [contentView setNeedsDisplay];
}

/* Override implementation to return a PDFContentView */
- (UIView *)contentView {
    if (!contentView) {
        contentView = [[PDFContentView alloc] initWithFrame:CGRectZero];
    }
    return contentView;
}

- (void)setPage:(CGPDFPageRef)page {
    pageRef = page;
    [(PDFContentView *) self.contentView setPage:page];
    // Also set the frame of the content view according to the page size
    CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    NSInteger rotationAngle = CGPDFPageGetRotationAngle(pageRef);
    if (rotationAngle == 90) {
        CGFloat height = rect.size.width;
        rect.size.width = rect.size.height;
        rect.size.height = height;
    }
    self.contentView.frame = rect;
}

- (void)setSelections:(NSArray *)selections {
    [(PDFContentView *) self.contentView setSelections:selections];
    [self setNeedsDisplay];
}

- (void)setHyperlinks:(NSArray *)hyperlinks {
    [(PDFContentView *) self.contentView setHyperlinks:hyperlinks];
    for (UIView* buttonView in [contentView subviews]) {
        [buttonView removeFromSuperview];
    }
    if (hyperlinks) {
        CGRect pageRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
        for (NSUInteger index=0; index < [hyperlinks count]; index++) {
            NSDictionary *link = hyperlinks[index];
            CGRect rect= [self getRectWithPageRect:pageRect forLink:link];
            [self addButtonForIndex:index withRect:rect];
        }
    }
    [self setNeedsDisplay];
}

- (CGRect)getRectWithPageRect:(CGRect)pageRect forLink:(NSDictionary *)link {
    CGRect rect = [[link objectForKey:@"frame"] CGRectValue];
    rect.origin.y = pageRect.size.height-(rect.origin.y+rect.size.height);
    return rect;
}

- (void)addButtonForIndex:(NSUInteger)index withRect:(CGRect)rect {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = rect;
    button.tag = index;
    button.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0.1 alpha:0.1];
    [button addTarget:self action:@selector(buttonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:button];
}

- (void)buttonTouchUpInside:(id)touchedButton {
    UIButton *button = touchedButton;
    NSDictionary *link = [(PDFContentView *) self.contentView hyperlinks][(NSUInteger) button.tag];
    NSLog(@"Link Clicked:%@",link);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[link objectForKey:@"targetUrl"]]];
}

@end
