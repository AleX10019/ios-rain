/*
 * Rain Dodge: a small original game for the rain port's first sideloaded app.
 * Drag the paddle along the bottom; raindrops fall faster as the score climbs; one hit ends the run.
 * Tap to start again. Plain UIKit + Core Graphics (no Metal/GL needed), manual retain/release.
 */
#import <UIKit/UIKit.h>

#define DROPS 48

typedef struct {
	CGFloat x, y, r, v;
	bool live;
} Drop;

@interface DodgeView : UIView {
	Drop drops[DROPS];
	CGFloat player, speed, spawn;
	CFTimeInterval last;
	NSInteger score, best;
	bool over;
	CADisplayLink *link;
}
@end

@implementation DodgeView

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor colorWithRed:0.05 green:0.07 blue:0.13 alpha:1];
		best = [[NSUserDefaults standardUserDefaults] integerForKey:@"best"];
		[self reset];
		link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
		[link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	}
	return self;
}

- (void)reset
{
	memset(drops, 0, sizeof(drops));
	player = self.bounds.size.width / 2;
	speed = 260;
	spawn = 0;
	score = 0;
	over = false;
	last = 0;
}

- (CGRect)paddle
{
	CGSize s = self.bounds.size;
	return CGRectMake(player - 45, s.height - 120, 90, 18);
}

- (void)tick:(CADisplayLink *)l
{
	CFTimeInterval now = l.timestamp;
	CGFloat dt = last == 0 ? 0 : (CGFloat)MIN(now - last, 0.05);
	last = now;
	if (over || dt == 0) {
		[self setNeedsDisplay];
		return;
	}
	CGSize s = self.bounds.size;
	speed += dt * 6;
	spawn -= dt;
	if (spawn <= 0) {
		for (int i = 0; i < DROPS; i++) {
			if (!drops[i].live) {
				drops[i] = (Drop){ .x = 20 + arc4random_uniform((uint32_t)MAX(s.width - 40, 1)),
					           .y = -20, .r = 7 + arc4random_uniform(8),
					           .v = speed * (0.8 + arc4random_uniform(40) / 100.0), .live = true };
				break;
			}
		}
		spawn = MAX(0.12, 0.6 - score * 0.004);
	}
	CGRect p = [self paddle];
	for (int i = 0; i < DROPS; i++) {
		Drop *d = &drops[i];
		if (!d->live) {
			continue;
		}
		d->y += d->v * dt;
		if (CGRectIntersectsRect(p, CGRectMake(d->x - d->r, d->y - d->r, 2 * d->r, 2 * d->r))) {
			over = true;
			if (score > best) {
				best = score;
				[[NSUserDefaults standardUserDefaults] setInteger:best forKey:@"best"];
			}
		} else if (d->y - d->r > s.height) {
			d->live = false;
			score++;
		}
	}
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGSize s = self.bounds.size;
	CGContextSetRGBFillColor(c, 0.45, 0.75, 1, 1);
	for (int i = 0; i < DROPS; i++) {
		if (drops[i].live) {
			CGContextFillEllipseInRect(c, CGRectMake(drops[i].x - drops[i].r, drops[i].y - drops[i].r,
			    2 * drops[i].r, 2 * drops[i].r));
		}
	}
	CGContextSetRGBFillColor(c, 1, 0.8, 0.25, 1);
	CGContextFillRect(c, [self paddle]);
	NSDictionary *big = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:34],
			       NSForegroundColorAttributeName: [UIColor whiteColor] };
	NSDictionary *small = @{ NSFontAttributeName: [UIFont systemFontOfSize:18],
				 NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.7] };
	[[NSString stringWithFormat:@"%ld", (long)score] drawAtPoint:CGPointMake(24, 60) withAttributes:big];
	[[NSString stringWithFormat:@"best %ld", (long)best] drawAtPoint:CGPointMake(24, 104) withAttributes:small];
	if (over) {
		NSString *t = @"Splash! Tap to retry";
		CGSize ts = [t sizeWithAttributes:big];
		[t drawAtPoint:CGPointMake((s.width - ts.width) / 2, s.height / 2 - ts.height) withAttributes:big];
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	player = [[touches anyObject] locationInView:self].x;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	if (over) {
		[self reset];
	}
	player = [[touches anyObject] locationInView:self].x;
}

@end

@interface DodgeController : UIViewController
@end

@implementation DodgeController
- (void)loadView
{
	self.view = [[[DodgeView alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
}
- (BOOL)prefersStatusBarHidden
{
	return YES;
}
@end

@interface DodgeApp : UIResponder <UIApplicationDelegate>
@property (nonatomic, retain) UIWindow *window;
@end

@implementation DodgeApp
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options
{
	self.window = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
	self.window.rootViewController = [[[DodgeController alloc] init] autorelease];
	[self.window makeKeyAndVisible];
	return YES;
}
@end

int
main(int argc, char *argv[])
{
	@autoreleasepool {
		return UIApplicationMain(argc, argv, nil, NSStringFromClass([DodgeApp class]));
	}
}
