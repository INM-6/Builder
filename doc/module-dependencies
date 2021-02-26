# Module files and Dependencies

Builder does explicitly not track dependencies between packages, but is designed
to work with what is there. This is necessary to be able to integrate well with
different environments on each machine. What builder can do, however, is to track
which modules where loaded during the build time. It is (for now) assumed that

* run-time dependencies are at least a sub-set of the build-time dependencies, 
  so that requiring build-time deps at run-time provides all package requirements,
  and
* build-time loaded modules are also available at run-time (not a given, if
  packages are built on a head node, but run on a compute node, for example).

Additional points to note are

* required modules are different on all systems, so module-names can not be
  hard-coded in planfiles or modulefile templates.
* Builder is not designed for cross-compiles.

