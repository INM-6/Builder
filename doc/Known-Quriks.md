
# FAQ

There are some behaviours that have not been completely straigtened out yet.
The following is a collection of workarounds for those strange spots.


## Missing GPG key

GPG signatures can not be verified without a corresponding public key. The
public keys are tracked in the repository with the plan files, just like the
checksums. If something goes wrong the signature may downloaded, but the key
registration may have failed. This will lead to an error like this:

    >>> checking /path/to/the/project/cache/packages/gsl-2.6.tar.gz...
    GPG Signature: gpg: Signature made Wed 21 Aug 2019 01:57:20 AM JST using RSA key ID AE05B3E9
    gpg: Can't check signature: No public key

Solution is currently simply deleting the `.sig` file. So in the above case
this does the trick:

    $ rm /path/to/the/project/cache/packages/gsl-2.6.tar.gz.sig

This causes the signature to be re-downloaded, but then should register the
public key in your keyring.
