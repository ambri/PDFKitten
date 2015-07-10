//
// Created by Adam Boardman on 06/12/2013.
// Copyright (c) 2013 Chalmers Göteborg. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface PDFLinkScanner : NSObject
+ (PDFLinkScanner *)scannerWithPage:(CGPDFPageRef)page;

- (NSArray *)findHyperlinks;
@end