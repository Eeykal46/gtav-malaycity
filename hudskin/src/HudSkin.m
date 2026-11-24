// HudSkin: restyles the existing native launcher (MPLauncherViewController in libgtacompat.dylib)
// into the "HUD" look (option 5). It does NOT replace any logic: every button, tab, setting and
// the Play path stay the native ones. Layout rules only touch views found through ivars that
// were read from the shipped binary; if any ivar/class is missing the skin does nothing.
// NOT COMPILED OR RUN. Spacing values are first-pass and need tuning on device.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static UIColor *Red(void){ return [UIColor colorWithRed:1.0 green:0.176 blue:0.255 alpha:1]; }

static id Ivar(id o, const char *name){
    Ivar v = class_getInstanceVariable(object_getClass(o), name);
    return v ? object_getIvar(o, v) : nil;
}
static BOOL Visible(UIView *v){ return v && !v.hidden && v.alpha > 0.01 && v.window != nil; }

static void SkinTitle(UILabel *t){
    if(![t isKindOfClass:UILabel.class] || !t.text.length) return;
    if([t.text rangeOfString:@"grand theft auto v" options:NSCaseInsensitiveSearch].location == NSNotFound) return;
    if([t.attributedText.string isEqualToString:@"GRAND THEFT AUTO V"] && t.tag == 0x4855) return;
    UIFont *f = [UIFont fontWithName:@"AvenirNextCondensed-HeavyItalic" size:64] ?: [UIFont systemFontOfSize:64 weight:UIFontWeightHeavy];
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:@"GRAND THEFT AUTO V"
        attributes:@{NSFontAttributeName:f, NSForegroundColorAttributeName:UIColor.whiteColor, NSKernAttributeName:@2}];
    [s addAttribute:NSForegroundColorAttributeName value:Red() range:NSMakeRange(17,1)];
    t.attributedText = s; t.numberOfLines = 3; t.adjustsFontSizeToFitWidth = YES; t.minimumScaleFactor = 0.5;
    t.tag = 0x4855;
}

static void Apply(UIViewController *vc){
    UIView *root = vc.view; CGRect b = root.bounds; UIEdgeInsets sa = root.safeAreaInsets;
    UIView *games = Ivar(vc,"_games");
    if(!games || !Visible(games)) return;                // only the Games tab is re-laid out
    UILabel *title = Ivar(vc,"_gameTitle");
    UIView *play = Ivar(vc,"_play");
    UIButton *bench = Ivar(vc,"_bench");
    if(!title || !play) return;                           // unknown layout: leave native

    CGFloat L = MAX(sa.left, 16) + 16, R = b.size.width - MAX(sa.right,16) - 16;
    CGFloat B = b.size.height - MAX(sa.bottom,10) - 14;

    SkinTitle(title);
    CGFloat tw = MIN(R - L - 260, 460);
    title.frame = CGRectMake(L, b.size.height*0.22, tw, 150);

    CGSize ps = CGSizeMake(200, 64);                      // angled PLAY, bottom-right
    play.transform = CGAffineTransformIdentity;
    play.frame = CGRectMake(R - ps.width, B - ps.height, ps.width, ps.height);
    play.transform = CGAffineTransformMake(1,0,-0.18,1,0,0);

    if([bench isKindOfClass:UIButton.class]){
        bench.frame = CGRectMake(L, B - 22, 200, 22);
        bench.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
}

static IMP gOrig;
static void Hooked(UIViewController *self, SEL _cmd){
    ((void(*)(id,SEL))gOrig)(self,_cmd);
    @try { Apply(self); } @catch(__unused id e) {}
}

__attribute__((constructor)) static void HudSkinInit(void){
    dispatch_async(dispatch_get_main_queue(), ^{
        Class c = NSClassFromString(@"MPLauncherViewController");
        Method m = c ? class_getInstanceMethod(c, @selector(viewDidLayoutSubviews)) : NULL;
        if(!m){ NSLog(@"[HudSkin] MPLauncherViewController not found; skin disabled"); return; }
        gOrig = method_setImplementation(m, (IMP)Hooked);
        NSLog(@"[HudSkin] installed");
    });
}
