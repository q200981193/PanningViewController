PanningViewController
=====================

A view controller that supports left, right, center, and bottom view controllers when sliding to expose

Usage
=====
```objective-c
//Create view controllers
ViewController *topViewController = [ViewController alloc] initWithNibName:@"topViewController" bundle:nil];
ViewController *rightViewController = [ViewController alloc] initWithNibName:@"rightViewController" bundle:nil];
ViewController *bottomViewController = [ViewController alloc] initWithNibName:@"bottomViewController" bundle:nil];
ViewController *leftViewController = [ViewController alloc] initWithNibName:@"leftViewController" bundle:nil];
ViewController *centerViewController = [ViewController alloc] initWithNibName:@"centerViewController" bundle:nil];

//Setup panning view controllers
PanningViewController *panningViewController = [PanningViewController alloc] init];
//Center is the only one required
[panningViewController setCenterViewController:leftViewController];

//Others are optional, if they're not set the view won't slide in that direction
[panningViewController setTopViewController:topViewController];
[panningViewController setTopViewController:rightViewController];
[panningViewController setTopViewController:bottomViewController];
[panningViewController setTopViewController:leftViewController];

//In AppDelegate
//Set the window's view controller to the panning view controller
//And that's it!
[self.window setRootViewController:panningViewController];
```
	