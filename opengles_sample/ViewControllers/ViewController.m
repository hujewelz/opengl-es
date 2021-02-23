//
//  ViewController.m
//  opengles_sample
//
//  Created by huluobo on 2021/2/20.
//

#import "ViewController.h"
#import "MGLView.h"

@interface ViewController ()
@property (strong, nonatomic) MGLView *glView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect bounds = [UIScreen mainScreen].bounds;
    self.glView = [[MGLView alloc] initWithFrame: bounds];
    [self.view addSubview:self.glView];
    [self.glView display];
}


@end
