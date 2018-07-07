# README

This is GNUstep CAAppKitBridge.
It is a part of the GNUstep QuartzCore, an implementation of the Core Animation APIs intended for use with GNUstep.

CAAppKitBridge aims to allow for *Cocoa compatible* automatic creation of CALayer tree that backs the existing NSView tree. This also covers
the creation and handling of CARenderer and OpenGL layers.

The difference between the Cocoa and GNUstep implementations of this is that GNUstep provides backwards compatibility - apps don't have to use CoreAnimation whatsoever. Beacuse of this, all of the work is implemented as a class category of NSView from libs-gui.

This project is currently work in progress - **not stable.**
