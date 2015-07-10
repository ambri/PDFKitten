#import "PageView.h"
#import "PDFPage.h"
#import "PDFPageDetailsView.h"
#import "PDFSelection.h"

#define PAGE_GAP 4

@interface PageView ()
@property(nonatomic, strong) PDFPageDetailsView *detailViewController;
@property(nonatomic, strong) NSArray *selections;
@property(nonatomic, strong) NSDictionary *pagedHyperlinks;
@end

@implementation PageView {
    BOOL dataLoaded;
}

@synthesize page, dataSource, detailViewController;

#pragma mark - Init and View layout

- (void)commonInit {
    visiblePages = [[NSMutableSet alloc] init];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.clipsToBounds = YES;

    _scrollView = [[UIScrollView alloc] initWithFrame:[self frameForScrollView]];
    _scrollView.backgroundColor = [UIColor lightGrayColor];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.bounces = YES;
    _scrollView.delegate = self;
    [self addSubview:_scrollView];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (void)reloadData {
    dataLoaded = NO;
    for (Page *p in visiblePages) {
        [p removeFromSuperview];
    }
    [visiblePages removeAllObjects];
    [self setNeedsLayout];
}

/* True if the page with given index is showing */
- (BOOL)isShowingPageForIndex:(NSInteger)index {
    for (Page *p in visiblePages) {
        if (p.pageNumber == index) {
            return YES;
        }
    }
    return NO;
}

/**
 * Find the index of the page if it is showing
 */
- (Page*)pageInVisiblePagesForIndex:(NSInteger)index {
    for (Page *p in visiblePages) {
        if (p.pageNumber == index) {
            return p;
        }
    }
    return nil;
}

- (CGRect)frameForScrollView {
    CGSize size = self.bounds.size;
    if (verticalScroll) {
        return CGRectMake(0, -PAGE_GAP/2, size.width, size.height + PAGE_GAP);
    } else {
        return CGRectMake(-PAGE_GAP/2, 0, size.width + PAGE_GAP, size.height);
    }
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidthWithGap = _scrollView.frame.size.width;
    CGFloat pageHeightWithGap = _scrollView.frame.size.height;
    CGSize pageSize = self.bounds.size;
    
    if (verticalScroll) {
        return CGRectMake(0, pageHeightWithGap * index + PAGE_GAP/2, pageSize.width, pageSize.height);
    } else {
        return CGRectMake(pageWidthWithGap * index + PAGE_GAP/2, 0, pageSize.width, pageSize.height);
    }
}

- (void)loadDataIfNeeded {
    if (dataLoaded) {
        return;
    }
    
    numberOfPages = [dataSource numberOfPagesInPageView:self];
    
    dataLoaded = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self loadDataIfNeeded];
    
    CGRect oldFrame = _scrollView.frame;
    CGRect newFrame = [self frameForScrollView];
    if (!CGRectEqualToRect(oldFrame, newFrame)) {
        // Strangely enough, if we do this assignment every time without the above
        // check, bouncing will behave incorrectly.
        _scrollView.frame = newFrame;
    }

    CGSize contentSize;
    if (verticalScroll) {
        contentSize = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height * numberOfPages);
    } else {
        contentSize = CGSizeMake(_scrollView.frame.size.width * numberOfPages, _scrollView.frame.size.height);
    }
    
    if (!CGSizeEqualToSize(_scrollView.contentSize, contentSize)) {
        _scrollView.contentSize = contentSize;
        if (verticalScroll) {
            _scrollView.contentOffset = CGPointMake(0, _scrollView.frame.size.height * pageNumber);
        } else {
            _scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width * pageNumber, 0);
        }
    } else {
    }
    
    CGRect visibleBounds = _scrollView.bounds;
    int firstNeededPageIndex = 0;
    int currentPageIndex = 0;
    long lastNeededPageIndex = 0;
    if (verticalScroll) {
        firstNeededPageIndex = (int) floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds));
        currentPageIndex = (int) floorf(CGRectGetMidY(visibleBounds) / CGRectGetHeight(visibleBounds));
        lastNeededPageIndex = (int) floorf((CGRectGetMaxY(visibleBounds) - 1) / CGRectGetHeight(visibleBounds));
    } else {
        firstNeededPageIndex = (int) floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
        currentPageIndex = (int) floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds));
        lastNeededPageIndex = (int) floorf((CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds));
    }
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex = MIN(numberOfPages - 1, lastNeededPageIndex);

    NSMutableSet *removedPages = [[NSMutableSet alloc] init];
    CGFloat currentZoomScale = 0;
    CGPoint currentContentOffset = CGPointMake(0,0);
    for (Page *aPage in visiblePages) {
        if (aPage.pageNumber < firstNeededPageIndex || aPage.pageNumber > lastNeededPageIndex) {
            [removedPages addObject:aPage];
            [aPage removeFromSuperview];
        }
        if (aPage.pageNumber == currentPageIndex) {
            currentZoomScale = aPage.zoomScale;
            currentContentOffset = aPage.contentOffset;
        }
    }
    [visiblePages minusSet:removedPages];
    [removedPages removeAllObjects];

    for (int i = firstNeededPageIndex; i <= lastNeededPageIndex; i++) {
        Page *aPage = [self pageInVisiblePagesForIndex:i];
        if (aPage != nil) {
            CGRect rect = [self frameForPageAtIndex:i];
            aPage.frame = rect;
            [aPage scrollViewDidZoom:nil];
            [aPage setNeedsDisplay];
            continue;
        }
        aPage = [dataSource pageView:self viewForPage:i];
        CGRect rect = [self frameForPageAtIndex:i];
        aPage.frame = rect;
        UIView *currentContentView = (aPage.detailedView) ? aPage.detailedView : aPage.contentView;
        if (currentZoomScale == 0) {
            CGFloat hScale = (CGRectGetWidth(rect) - 2) / CGRectGetWidth(currentContentView.bounds);
            CGFloat vScale = (CGRectGetHeight(rect) - 2) / CGRectGetHeight(currentContentView.bounds);
            CGFloat scale = MIN(hScale, vScale);
            [aPage setZoomScale:scale animated:NO];
        } else {
            [aPage setZoomScale:currentZoomScale];
            CGPoint contentOffset = CGPointMake(0, 0);
            if (verticalScroll) {
                contentOffset.x = currentContentOffset.x;
                if (aPage.pageNumber < currentPageIndex) {
                    contentOffset.y = aPage.contentView.frame.size.height-aPage.frame.size.height;
                } else {
                    contentOffset.y = 0;
                }
            } else {
                contentOffset.y = currentContentOffset.y;
                if (aPage.pageNumber < currentPageIndex) {
                    contentOffset.x = aPage.contentView.frame.size.width-aPage.frame.size.width;
                } else {
                    contentOffset.x = 0;
                }
            }
            aPage.contentOffset = contentOffset;
        }
        [aPage scrollViewDidZoom:nil];

        [visiblePages addObject:aPage];

        [_scrollView addSubview:aPage];
        [_scrollView sendSubviewToBack:aPage];
        NSMutableArray *pageSelections = [NSMutableArray array];
        for (PDFSelection *selection in _selections) {
            if (selection.pageNumber-1 == aPage.pageNumber) {
                [pageSelections addObject:selection];
            }
        }
        [(PDFPage *)aPage setSelections:pageSelections];
        NSArray *hyperlinks = [_pagedHyperlinks objectForKey:@(aPage.pageNumber)];
        [(PDFPage *)aPage setHyperlinks:hyperlinks];
        [aPage setNeedsDisplay];
    }
}

- (Page *)pageAtIndex:(NSInteger)index {
    NSSet *pages = [visiblePages copy];
    for (Page *p in pages) {
        if (p.pageNumber == index) {
            return p;
        }
    }
    return nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self setNeedsLayout];
}

/* Animated scrolling did stop */
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([dataSource respondsToSelector:@selector(pageView:didScrollToPage:)]) {
        [dataSource pageView:self didScrollToPage:self.page];
    }
}

/* User touch scrolling did stop */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([dataSource respondsToSelector:@selector(pageView:didScrollToPage:)]) {
        [dataSource pageView:self didScrollToPage:self.page];
    }
}


#pragma mark - Page numbers

/* Scrolls to the given page */
- (void)setPage:(NSInteger)aPage animated:(BOOL)animated {
    CGRect rect = self.frame;
    if (verticalScroll) {
        rect.origin.y = CGRectGetHeight(_scrollView.frame) * aPage;
    } else {
        rect.origin.x = CGRectGetWidth(_scrollView.frame) * aPage;
    }
    [_scrollView scrollRectToVisible:rect animated:animated];
    if (!animated) {
        if ([dataSource respondsToSelector:@selector(pageView:didScrollToPage:)]) {
            [dataSource pageView:self didScrollToPage:self.page];
        }
    }
}

/* Scrolls to the given page */
- (void)setPage:(NSInteger)aPage {
    [self setPage:aPage animated:NO];
}

/* Returns the current page number */
- (NSInteger)page {
    NSInteger number = 0;
    if (verticalScroll) {
        CGFloat minimumVisibleY = CGRectGetMinY(_scrollView.bounds);
        CGFloat pageHeight = CGRectGetHeight(_scrollView.frame);
        number += floorf(minimumVisibleY / (pageHeight));
    } else {
        CGFloat minimumVisibleX = CGRectGetMinX(_scrollView.bounds);
        CGFloat pageWidth = CGRectGetWidth(_scrollView.frame);
        number += floorf(minimumVisibleX / (pageWidth));
    }
    number = MAX(number,0);
    number = MIN(number,numberOfPages-1);
    return number;
}

/* Show detailed view when info button has been pressed */
- (void)detailedInfoButtonPressed:(UIButton *)sender {
    if (![dataSource respondsToSelector:@selector(pageView:detailedViewForPage:)]) {
        return;
    }

    self.detailViewController = [dataSource pageView:self detailedViewForPage:self.page];
    UIView *detailedView = [self.detailViewController view];

    Page *currentPage = nil;

    for (Page *p in visiblePages) {
        if (p.pageNumber == self.page) {
            currentPage = p;
            break;
        }
    }

    if (!currentPage) return;

    if (currentPage.detailedView) {
        [UIView transitionFromView:currentPage.detailedView toView:currentPage duration:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft completion:nil];
        currentPage.detailedView = nil;
        return;
    }

    currentPage.detailedView = detailedView;
    detailedView.frame = currentPage.frame;
    [UIView transitionFromView:currentPage toView:detailedView duration:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft completion:nil];
}

- (void)setVerticalScroll:(BOOL)vertical {
    verticalScroll = vertical;
}

- (void)setSelections:(NSArray *)selections {
    _selections = selections;
    for (PDFPage *p in visiblePages) {
        NSMutableArray *pageSelections = [NSMutableArray array];
        for (PDFSelection *selection in selections) {
            if (selection.pageNumber-1 == p.pageNumber) {
                [pageSelections addObject:selection];
            }
        }
        [p setSelections:pageSelections];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    pageNumber = [self page];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    CGRect rect = self.frame;
    if (verticalScroll) {
        rect.origin.y = floorf(rect.size.height * pageNumber);
    } else {
        rect.origin.x = floorf(rect.size.width * pageNumber);
    }
    _scrollView.contentOffset = rect.origin;
}

- (void)setPagedHyperlinks:(NSDictionary *)pagedHyperlinks {
    _pagedHyperlinks = pagedHyperlinks;
    for (PDFPage *p in visiblePages) {
        NSArray *hyperlinks = [pagedHyperlinks objectForKey:@(p.pageNumber)];
        [p setHyperlinks:hyperlinks];
    }
}

@end
