#import "PDFSelection.h"
#import "PDFRenderingState.h"

CGFloat horizontal(CGAffineTransform transform) {
	return transform.tx / transform.a;
}

@implementation PDFSelection
@synthesize frame, transform;

+ (PDFSelection *)selectionWithState:(PDFRenderingState *)state {
	PDFSelection *selection = [[PDFSelection alloc] init];
	selection.initialState = state;
	return selection;
}

- (CGAffineTransform)transform {
	return CGAffineTransformConcat([self.initialState textMatrix], [self.initialState ctm]);
}

- (CGRect)frame {
	return CGRectMake(0, self.descent, self.width, self.height);
}

- (CGFloat)height {
	return self.ascent - self.descent;
}

- (CGFloat)width {
	return horizontal(self.finalState.textMatrix) - horizontal(self.initialState.textMatrix);
}

- (CGFloat)ascent {
	return MAX([self ascentInUserSpace:self.initialState], [self ascentInUserSpace:self.finalState]);
}

- (CGFloat)descent {
	return MIN([self descentInUserSpace:self.initialState], [self descentInUserSpace:self.finalState]);
}

- (CGFloat)ascentInUserSpace:(PDFRenderingState *)state {
	return state.font.fontDescriptor.ascent * state.fontSize / [state.font unitsPerEm];
}

- (CGFloat)descentInUserSpace:(PDFRenderingState *)state {
	return state.font.fontDescriptor.descent * state.fontSize / [state.font unitsPerEm];
}

- (void)dealloc {
    
    if (_initialState)
        _initialState = nil;
    
    if (_finalState)
        _finalState = nil;
	
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"foundLocation=%lu", (unsigned long)self.foundLocation];
    [description appendFormat:@", pageNumber=%lu", (unsigned long)self.pageNumber];
    [description appendFormat:@", searchContext=%@", self.searchContext];
    [description appendFormat:@", frame=(%f,%f,%f,%f)", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height];
    [description appendString:@">"];
    return description;
}

@end
