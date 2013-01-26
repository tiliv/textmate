#import <text/types.h>
#import <OakAppKit/OakGradientView.h>

@protocol OTVStatusBarDelegate <NSObject>
- (void)showLanguageSelector:(id)sender;
- (void)showBundleItemSelector:(id)sender;
- (void)showTabSizeSelector:(id)sender;
- (void)showSymbolSelector:(id)sender;
- (void)toggleMacroRecording:(id)sender;
@end

@interface OTVStatusBar : OakGradientView
- (void)setCaretPosition:(std::string const&)range;
@property (nonatomic, copy)   NSString* grammarName;
@property (nonatomic, copy)   NSString* symbolName;
@property (nonatomic, assign) BOOL isMacroRecording;
@property (nonatomic, assign) BOOL softTabs;
@property (nonatomic, assign) int32_t tabSize;

@property (nonatomic, assign) id <OTVStatusBarDelegate> delegate;
@end
