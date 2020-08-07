# Builder Configuration

  Builder is designed to require only very minimal configuration. Upon its
  first build or when explicitly called with `build configure` a file
  `.buildrc` is created if it does not exist yet. This file contains variables
  that define various locations used in the build and install process.  When
  the file is generated automatically Builder pre-fills some guessed defaults
  that point to your home directory. While this quickly gets you started,
  installing a lot of software into your `$HOME` is usually not a good idea and
  you should set `$TARGET_PATH` to a better location.
