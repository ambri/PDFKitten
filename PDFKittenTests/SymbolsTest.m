//
//  SymbolsTest.m
//  PDFKitten
//
//  Created by Adam Boardman on 03/12/2013.
//  Copyright (c) 2013 Chalmers Göteborg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PDFKitten.h"

@interface SymbolsTest : XCTestCase

@end

@implementation SymbolsTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testDetectSymbols {
    NSURL *pdfURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Symbols" ofType:@"pdf"]];
    PDFKitten *pdfKitten = [PDFKitten loadDocument:pdfURL];
    [pdfKitten startSearchFromPage:0 withKeyword:@"\""];
    while ([pdfKitten scanInProgress]) {
        sleep(1);
    }
    NSArray *selections=[pdfKitten getSelections];
    XCTAssertEqual((int)[selections count], 3, @"wrong number of selections");

    [pdfKitten startSearchFromPage:0 withKeyword:@"\'"];
    while ([pdfKitten scanInProgress]) {
        sleep(1);
    }
    selections=[pdfKitten getSelections];
    XCTAssertEqual((int)[selections count], 1, @"wrong number of selections");

    [pdfKitten startSearchFromPage:0 withKeyword:@"a-b"];
    while ([pdfKitten scanInProgress]) {
        sleep(1);
    }
    selections=[pdfKitten getSelections];
    XCTAssertEqual((int)[selections count], 1, @"wrong number of selections");
}

@end
