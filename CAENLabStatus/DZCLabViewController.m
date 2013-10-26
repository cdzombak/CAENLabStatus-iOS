@import MapKit;
@import QuartzCore;

#import "DZCLabViewController.h"
#import "DZCLabTableViewManager.h"
#import "CDZTableViewSplitDelegate.h"

#import "DZCDataController.h"
#import "DZCLab.h"

#import "UIColor+DZCColors.h"

static const CGFloat DZCLabVCMapZoom = 0.35f;

static const CGFloat DZCLabVCMapVisibleHeight = 200.f;
static const CGFloat DZCLabVCMapParallax = 12.f;

@interface DZCLabViewController () <UIScrollViewDelegate>

@property (nonatomic, assign) CLLocationCoordinate2D mapZoomLocation;
@property (nonatomic, readonly) CGFloat mapViewYOrigin;
@property (nonatomic, readonly) CGFloat mapViewHeight;

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bgView;

@property (nonatomic, strong) DZCLabTableViewManager *tvManager;
@property (nonatomic, strong) CDZTableViewSplitDelegate *tvSplitDelegate;

@property (nonatomic, assign) BOOL showsParallaxView;

@property (nonatomic, readwrite, strong) DZCLab *lab;

@end

@implementation DZCLabViewController

- (id)initWithLab:(DZCLab *)lab
{
    self = [super init];
    if (self) {
        self.lab = lab;
        self.title = self.lab.humanName;

        self.showsParallaxView = YES;
    }
    return self;
}

#pragma mark - UIViewController view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.clipsToBounds = YES;

    UITableViewStyle tvStyle = [DZCLabTableViewManager tableViewStyleForLab:self.lab];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:tvStyle];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;
    [self.view addSubview:self.tableView];

    self.tvManager = [DZCLabTableViewManager tableViewManagerForLab:self.lab dataController:self.dataController];
    [self.tvManager configureTableView:self.tableView];
    self.tvSplitDelegate = [[CDZTableViewSplitDelegate alloc] initWithScrollViewDelegate:self tableViewDelegate:self.tableView.delegate];
    self.tableView.delegate = self.tvSplitDelegate;

    if (self.showsParallaxView) [self setupParallaxView];

    CDZWeakSelf weakSelf = self;
    self.tvManager.vcPushBlock = ^(UIViewController *vc) {
        CDZStrongSelf sSelf = weakSelf;
        UINavigationController *targetVC = sSelf.padDetailNavigationController ?: sSelf.navigationController;
        [targetVC pushViewController:vc animated:YES];
    };

    [self.tvManager prepareData];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in selectedIndexPaths) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.tableView flashScrollIndicators];
}

#pragma mark - UI Interactions

- (void)headerViewTouched:(id)sender
{
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.mapZoomLocation
                                                   addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = self.lab.humanName;
    [mapItem openInMapsWithLaunchOptions:nil];
}

#pragma mark - Top view and parallax

- (void)setupParallaxView
{
    CGRect bgFrame = (CGRect){CGPointMake(0, DZCLabVCMapVisibleHeight), self.tableView.bounds.size};

    self.bgView = [[UIView alloc] initWithFrame:bgFrame];
    self.bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.bgView.backgroundColor = self.view.backgroundColor;

    [self.tableView addSubview:self.bgView];
    [self.tableView sendSubviewToBack:self.bgView];

    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), DZCLabVCMapVisibleHeight)];
    tableHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableHeaderView.backgroundColor = [UIColor clearColor];

    UIView *blackBorderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, DZCLabVCMapVisibleHeight-1.0, CGRectGetWidth(self.view.bounds), 0.5)];
    blackBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    blackBorderView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    [tableHeaderView addSubview:blackBorderView];

    self.tableView.tableHeaderView = tableHeaderView;

    UIGestureRecognizer *headerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerViewTouched:)];
    [tableHeaderView addGestureRecognizer:headerTapRecognizer];

    CGRect mapViewFrame = CGRectMake(-DZCLabVCMapParallax, self.mapViewYOrigin, CGRectGetWidth(self.view.bounds)+2*DZCLabVCMapParallax, self.mapViewHeight);

    self.mapView = [[MKMapView alloc] initWithFrame:mapViewFrame];

    self.mapView.userInteractionEnabled = NO;
    self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.showsPointsOfInterest = NO;
    self.mapView.showsUserLocation = YES;

    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapZoomLocation, DZCLabVCMapZoom*DZC_METERS_PER_MILE, DZCLabVCMapZoom*DZC_METERS_PER_MILE);
    [self.mapView setRegion:viewRegion animated:NO];
    [self.mapView addAnnotation:self.lab];

    UIInterpolatingMotionEffect *mapHorizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    mapHorizontalEffect.minimumRelativeValue = @(-DZCLabVCMapParallax);
    mapHorizontalEffect.maximumRelativeValue = @(DZCLabVCMapParallax);
    [self.mapView addMotionEffect:mapHorizontalEffect];

    UIInterpolatingMotionEffect *mapVerticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    mapVerticalEffect.minimumRelativeValue = @(-DZCLabVCMapParallax);
    mapVerticalEffect.maximumRelativeValue = @(DZCLabVCMapParallax);
    [self.mapView addMotionEffect:mapVerticalEffect];

    [self.view addSubview:self.mapView];
    [self.view sendSubviewToBack:self.mapView];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.showsParallaxView) return;

    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGRect mapViewFrame = self.mapView.frame;
    mapViewFrame.origin.y = self.mapViewYOrigin - (scrollOffset / 3.5f);
    self.mapView.frame = mapViewFrame;
}

#pragma mark - Property overrides

- (void)setLab:(DZCLab *)lab
{
    _lab = lab;
    self.mapZoomLocation = lab.coordinate;
}

- (void)setPadDetailNavigationController:(UINavigationController *)padDetailNavigationController
{
    _padDetailNavigationController = padDetailNavigationController;
    self.showsParallaxView = _padDetailNavigationController == nil || self.lab.subLabs.count == 0;
}

- (CGFloat)mapViewHeight {
    return CGRectGetHeight(self.view.bounds)*0.85f;
}

- (CGFloat)mapViewYOrigin {
    return -0.2f*self.mapViewHeight;
}

@end
