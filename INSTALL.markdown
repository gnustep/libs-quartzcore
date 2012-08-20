Installing
==========

*Last updated: August 20, 2012*

Please refer to README for more detailed explanation of requirements,
supported features and how to use GNUstep QuartzCore!

 1. Take a look at the README for requirements. You'll need OpenGL headers,
    cairo, gnustep-base, gnustep-gui, opal, libobjc2, and a modern compiler
    such as clang. gcc-4.6+ will probably work, too. For requirements of
    each individual library as well as installation procedure, refer to their
    documentation (or refer to online search engines).
 2. opal will need to be patched with `opal-nsfonthacks.patch`.
 3. Just as with any other GNUstep library, don't forget to source the
    `GNUstep.sh` file. Then just run:

        make && sudo -E make install

    from the `quartzcore` directory from the repository. If you'd prefer not 
    to have test programs installed, do the same from the `Source/` 
    subdirectory, thus avoiding installation of programs from `Tests/`
    directory.

Tested under Ubuntu 12.04. Supplied Xcode projects can be used to build
a test version for OS X. Just use the `UsingGNUstepImpl` target when building
test code.

Please report any problems to the `discuss-gnustep` mailing list, so these
instructions can be improved.

