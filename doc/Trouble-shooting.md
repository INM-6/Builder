
# FAQ

There are some behaviours that have not been completely straightened out yet,
others have a well known cause and maybe even a solution. The following
sections are a collection of workarounds for those strange spots.


## "Can't check signature: No public key"

GPG signatures can not be verified without a corresponding public key. The
public keys are tracked in the repository with the plan files, just like the
checksums. If something goes wrong, the signature may downloaded, but the key
registration in GPG may have failed. This will lead to an error like this:

    >>> checking /path/to/the/project/cache/packages/gsl-2.6.tar.gz...
    GPG Signature: gpg: Signature made Wed 21 Aug 2019 01:57:20 AM JST using RSA key ID AE05B3E9
    gpg: Can't check signature: No public key

Solution is currently simply to delete the `.sig` file. So in the above case
this does the trick:

    $ rm /path/to/the/project/cache/packages/gsl-2.6.tar.gz.sig

This causes the signature to be re-downloaded, and retry to register the public
key in your keyring.


## "realpath: command not found"

When installing Builder on a new system that does not have the `coreutils`
package installed you may see an error like the following:

    /some/path/to/bin/build: line 20: realpath: command not found

The solution is to install `coreutils` with the package manager best suited in
your situation. For example on MacOS this might be `brew install coreutils` or
`conda install coreutils`, depending on your setup.
