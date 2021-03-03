
# Testing

  Builder and its planfiles can be tested by running the [BATS
  test-suite][bats-doc].  Similar to Builder itself, BATS is an all-bash test
  environment. The tests are automatically collected and can be run jointly or
  by single file with

  ```bash
  cd path/to/Builder

  bats tests/
  # or
  bats "tests/modulefile.bats"
  ```

  This testing framework is aimed at developers testing during the development
  of Builder. The packages installed are explicitly not tested, and should be
  checked in a higher level integration testing.


## Installation

  If you do not have BATS installed, you can get the latest development version
  by downloading the [BATS git repository][bats-git]. An even simpler aproach
  is to install the last release with Builder itself:

  ```bash
  module load Builder
  build bats
  ```

  In this case you can just load the BATS module and run the tests as mentioned
  above:

  ```bash
  module load bats
  cd path/to/Builder
  bats tests/
  ```

[bats-doc]: https://bats-core.readthedocs.io BATS Documentation
[bats-git]: https://github.com/bats-core/bats-core BATS Repository
