#import "OTVStatusBar.h"
#import <OakAppKit/OakAppKit.h>
#import <OakAppKit/NSImage Additions.h>

static NSTextField* OakCreateTextField (NSString* label)
{
	NSTextField* res = [[NSTextField alloc] initWithFrame:NSZeroRect];
	[res setBordered:NO];
	[res setEditable:NO];
	[res setSelectable:NO];
	[res setBezeled:NO];
	[res setDrawsBackground:NO];
	[res setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
	[res setStringValue:label];
	[res setAlignment:NSRightTextAlignment];
	[[res cell] setBackgroundStyle:NSBackgroundStyleRaised];
	return res;
}

static NSPopUpButton* OakCreatePopUpButton (NSString* initialItem = nil)
{
	NSPopUpButton* res = [NSPopUpButton new];
	[[res cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[res setBordered:NO];
	[res setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];

	if(initialItem)
	{
		NSMenu* menu = [NSMenu new];
		[menu addItemWithTitle:initialItem action:@selector(nop:) keyEquivalent:@""];
		res.menu = menu;
	}

	return res;
}

static NSButton* OakCreateImageButton (NSImage* image)
{
	NSButton* res = [NSButton new];

	[[res cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[res setButtonType:NSMomentaryChangeButton];
	[res setBezelStyle:NSRecessedBezelStyle];
	[res setBordered:NO];

	[res setImage:image];
	[res setImagePosition:NSImageOnly];

	// [res setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
	// [res setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationVertical];

	return res;
}

static NSImageView* OakCreateImageView (NSImage* image)
{
	NSImageView* res = [[NSImageView alloc] initWithFrame:NSZeroRect];
	[res setImage:image];
	return res;
}

@interface OTVStatusBar ()
{
	text::range_t caretPosition;
}
- (void)update;
@property (nonatomic) CGFloat recordingTime;
@property (nonatomic, retain) NSTimer* recordingTimer;
@property (nonatomic, retain) NSImage* pulsedRecordingIndicator;
@end

const NSInteger BundleItemSelector = 1;

@implementation OTVStatusBar
- (id)initWithFrame:(NSRect)aRect
{
	if(self = [super initWithGradient:[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithCalibratedWhite:1.000 alpha:0.68], 0.0, [NSColor colorWithCalibratedWhite:1.000 alpha:0.5], 0.0416, [NSColor colorWithCalibratedWhite:1.000 alpha:0.0], 1.0, nil] inactiveGradient:[[NSGradient alloc] initWithColorsAndLocations: [NSColor colorWithCalibratedWhite:1.000 alpha:0.68], 0.0, [NSColor colorWithCalibratedWhite:1.000 alpha:0.5], 0.0416, [NSColor colorWithCalibratedWhite:1.000 alpha:0.0], 1.0, nil]])
	{
		NSTextField* lineLabel          = OakCreateTextField(@"Line:");
		NSTextField* selectionString    = OakCreateTextField(@"1:1");
		NSImageView* dividerOne         = OakCreateImageView([NSImage imageNamed:@"Divider" inSameBundleAsClass:[self class]]);
		NSPopUpButton* grammarPopUp     = OakCreatePopUpButton(@"Objective-C++");
		NSImageView* dividerTwo         = OakCreateImageView([NSImage imageNamed:@"Divider" inSameBundleAsClass:[self class]]);
		NSPopUpButton* tabSizePopUp     = OakCreatePopUpButton(@"Tab Size: 3");
		NSImageView* dividerThree       = OakCreateImageView([NSImage imageNamed:@"Divider" inSameBundleAsClass:[self class]]);
		NSPopUpButton* bundleItemsPopUp = OakCreatePopUpButton(@"[GEAR]");
		NSImageView* dividerFour        = OakCreateImageView([NSImage imageNamed:@"Divider" inSameBundleAsClass:[self class]]);
		NSPopUpButton* symbolPopUp      = OakCreatePopUpButton(@"- initWithFrame:");
		NSImageView* dividerFive        = OakCreateImageView([NSImage imageNamed:@"Divider" inSameBundleAsClass:[self class]]);
		NSButton* macroRecordingImage   = OakCreateImageButton([NSImage imageNamed:@"Recording" inSameBundleAsClass:[self class]]);

		bundleItemsPopUp.pullsDown = YES;
		tabSizePopUp.pullsDown     = YES;

		NSMenu* menu = [NSMenu new];
		NSMenuItem* item = [NSMenuItem new];
		item.title = @"";
		item.image = [NSImage imageNamed:NSImageNameActionTemplate];
		[menu addItem:item];
		[menu addItemWithTitle:@"C" action:@selector(nop:) keyEquivalent:@""];
		[menu addItemWithTitle:@"Objective-C" action:@selector(nop:) keyEquivalent:@""];
		bundleItemsPopUp.menu = menu;

		NSView* wrappedBundleItemsPopUpButton = [NSView new];
		[wrappedBundleItemsPopUpButton addSubview:bundleItemsPopUp];
		[bundleItemsPopUp setTranslatesAutoresizingMaskIntoConstraints:NO];
		[wrappedBundleItemsPopUpButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[popup]|" options:0 metrics:nil views:@{ @"popup" : bundleItemsPopUp }]];
		[wrappedBundleItemsPopUpButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[popup]|" options:0 metrics:nil views:@{ @"popup" : bundleItemsPopUp }]];

		menu = [NSMenu new];
		[menu addItemWithTitle:@"Tab Size: 3" action:@selector(nop:) keyEquivalent:@""];
		[menu addItemWithTitle:@"3" action:@selector(nop:) keyEquivalent:@""];
		[menu addItemWithTitle:@"4" action:@selector(nop:) keyEquivalent:@""];
		tabSizePopUp.menu = menu;

		// [symbolPopUp setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
		[symbolPopUp setContentHuggingPriority:NSLayoutPriorityDefaultLow-1 forOrientation:NSLayoutConstraintOrientationHorizontal];

		NSDictionary* views = @{
			@"line"         : lineLabel,
			@"selection"    : selectionString,
			@"dividerOne"   : dividerOne,
			@"grammar"      : grammarPopUp,
			@"dividerTwo"   : dividerTwo,
			@"items"        : wrappedBundleItemsPopUpButton,
			@"dividerThree" : dividerThree,
			@"tabSize"      : tabSizePopUp,
			@"dividerFour"  : dividerFour,
			@"symbol"       : symbolPopUp,
			@"dividerFive"  : dividerFive,
			@"recording"    : macroRecordingImage,
		};

		for(NSView* view in [views allValues])
		{
			[view setTranslatesAutoresizingMaskIntoConstraints:NO];
			[self addSubview:view];
		}

		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[line]-[selection(>=32)]-8-[dividerOne(==1)]-(-2)-[grammar(==115)]-5-[dividerTwo(==1)]-(-2)-[tabSize]-4-[dividerThree(==1)]-5-[items(==30)]-4-[dividerFour(==1)]-(-2)-[symbol]-5-[dividerFive(==1)]-6-[recording]-14-|" options:0 metrics:nil views:views]];
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[line]-5-|" options:0 metrics:nil views:views]];
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[selection]-5-|" options:0 metrics:nil views:views]];
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[grammar(==dividerOne,==items,==tabSize,==symbol,==recording)]|" options:0 metrics:nil views:views]];
	}
	return self;
}

- (NSSize)intrinsicContentSize
{
	return NSMakeSize(NSViewNoInstrinsicMetric, 24);
}

- (void)drawRect:(NSRect)aRect
{
	[[NSColor windowBackgroundColor] set]; NSRectFill(aRect);
	
	[super drawRect:aRect];
}

- (void)update
{
#if 0
	size_t line = caretPosition.min().line, column = caretPosition.min().column;

	std::string const lineNumberText = "Line: " + text::pad(line+1, 4) + "\u2003" /* Em Space */ + "Column: " + text::pad(column+1, 3);
	std::string const tabSizeText    = std::string(softTabs ? "Soft Tabs:" : "Tab Size:") + "\u2003" /* Em Space */ + text::pad(tabSize, 4);
	static NSImage* gearImage        = [[NSImage imageNamed:@"Statusbar Gear" inSameBundleAsClass:[self class]] retain];
	static NSImage* languageIcon     = [[NSImage imageNamed:@"Languages" inSameBundleAsClass:[self class]] retain];

	struct sb::cell_t const cellList[] =
	{
		sb::cell_t::info(lineNumberText),
		sb::cell_t::popup([grammarName UTF8String] ?: "-",     @selector(showLanguageSelector:),    self.delegate).set_image(languageIcon).size(110),
		sb::cell_t::popup(gearImage,                           @selector(showBundleItemSelector:),  self.delegate).set_tag(BundleItemSelector),
		sb::cell_t::popup(tabSizeText,                         @selector(showTabSizeSelector:),     self.delegate),
		sb::cell_t::popup([symbolName UTF8String] ?: "Symbol", @selector(showSymbolSelector:),      self.delegate).size(200, CGFLOAT_MAX),
		sb::cell_t::button(pulsedRecordingIndicator,           @selector(toggleMacroRecording:),    self.delegate).no_padding().size(17),
		sb::cell_t::info().size(15),
	};
	SetCells(self, cellList);
#endif
}

- (void)updateMacroRecordingAnimation:(NSTimer*)aTimer
{
	NSImage* startImage = [NSImage imageNamed:@"RecordingMacro" inSameBundleAsClass:[self class]];
	self.pulsedRecordingIndicator = [[[NSImage alloc] initWithSize:startImage.size] autorelease];

	[_pulsedRecordingIndicator lockFocus];
	CGFloat fraction = oak::cap(0.00, 0.50 + 0.50 * sin(_recordingTime), 1.0);
	[startImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:fraction];
	[_pulsedRecordingIndicator unlockFocus];

	[self update];
	_recordingTime += 0.075;
}

// ==============
// = Properties =
// ==============

- (void)setGrammarName:(NSString*)newGrammarName
{
	[_grammarName release];
	_grammarName = [newGrammarName copy];
	[self update];
}

- (void)setSymbolName:(NSString*)newSymbolName
{
	[_symbolName release];
	_symbolName = [newSymbolName copy];
	[self update];
}

- (void)setRecordingTimer:(NSTimer*)aTimer
{
	if(_recordingTimer != aTimer)
	{
		[_recordingTimer invalidate];
		[_recordingTimer release];
		_recordingTimer = [aTimer retain];
	}
}

- (void)setIsMacroRecording:(BOOL)flag
{
	_isMacroRecording = flag;
	if(_isMacroRecording)
	{
		_recordingTime = 0;
		self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(updateMacroRecordingAnimation:) userInfo:nil repeats:YES];
	}
	else
	{
		self.pulsedRecordingIndicator = nil;
		self.recordingTimer = nil;
	}
	[self update];
}

- (void)setCaretPosition:(std::string const&)range
{
	caretPosition = range;
	[self update];
}

- (void)setTabSize:(int32_t)size
{
	_tabSize = size;
	[self update];
}

- (void)setSoftTabs:(BOOL)flag
{
	_softTabs = flag;
	[self update];
}

- (void)dealloc
{
	self.grammarName = nil;
	self.symbolName = nil;
	self.recordingTimer = nil;
	[super dealloc];
}
@end
