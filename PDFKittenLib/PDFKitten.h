//
//  PDFKitten.h
//  PDFKitten
//

#import <Foundation/Foundation.h>

@protocol PDFKittenDelegate

- (void)scanResultsUpdated:(NSArray*)selections;

- (void)hyperlinks:(NSDictionary *)pagedHyperlinks;

@end


@interface PDFKitten : NSObject

@property (nonatomic, weak) id <PDFKittenDelegate> delegate;

@property(nonatomic) BOOL hyperlinkFindInProgress;

+ (PDFKitten *)loadDocument:(NSURL *)url;

- (id)initWithUrl:(NSURL *)url;

- (NSInteger)numberOfPages;

- (CGPDFPageRef)getPage:(NSInteger)number;

- (void)startSearchFromPage:(NSInteger)pageNumber withKeyword:(NSString*)keyword;
- (void)stopSearch;

- (BOOL)scanInProgress;

- (NSArray*)getSelections;

- (void)findHyperlinksForPage:(NSInteger)page;

- (BOOL)hyperlinkFindInProgress;

- (NSArray *)getHyperlinksForPage:(int)page;

@end
