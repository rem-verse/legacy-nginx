# Legacy NGINX Builds #

*current NGINX Version: 1.27.0*
*current OpenSSL Version: 1.0.2u*

While we're working on a longer term safer solution, rem-verse is making
available builds of NGINX which have statically linked in versions of
OpenSSL that still support SSLv3. While this is a bad idea, legacy restoration
services need an answer, and the goal is to provide as safe of a build as
possible, that can run on a modern OS.

> [!CAUTION]
> All versions of OpenSSL or derivatives that support SSLv3 should be considered
> unsafe, and SSLv3 is known to be broken. You should only run this when it is
> absolutely necessary, and we highly recommend running these binaries that
> support SSLv3 in some sort of security container like
> [Firecracker with the Jailer](https://firecracker-microvm.github.io/).

We are currently packaging for every source available through the tool we use
to make the actual underlying packages [nFPM](https://github.com/goreleaser/nfpm),
but if we don't package for your particular OS feel free to use the build scripts
available in this repository to build NGINX yourself.

## Packages ##

### Installing Pre-Built Packages ###

We publish prebuilt apt packages that you can use with:

```
wget -qO - https://legacy-nginx.apt.rem-verse.com/packaging.asc | sudo tee /etc/apt/trusted.gpg.d/legacy-nginx.asc
sudo add-apt-repository "deb https://legacy-nginx.apt.rem-verse.com/ production main"
sudo apt update
sudo apt install legacy-nginx
```

You can also use our prebuilt docker images: `docker pull remverse/legacy-nginx:1.27.0`

### Building ###

To run a build locally manually simply run:
`./build-scripts/building/nginx.sh`, or `./build-scripts/building/openssl.sh`
from within the root directory of this project. It won't do any specific error
checking, but you should have a C compiler, and a few base native compiling
dependencies. If you run into any errors from the build scripts you can't
interpret feel free to file an issue, and we can try our best to help.

To choose the version of openssl, and nginx set the environment variables:
`NGINX_VERSION`, and `OPENSSL_VERSION`. We will automatically set them to
the "best" versions at the same time.

Although our scripts do fetch from our mirror, if you would truly like to build
yourself, you can fetch the assets directly from our mirror.

All assets used to build an official release are mirrored for safety, and
distribution speeds on the domain: <legacy-nginx-ci.archive.rem-verse.com>.
You can see the script that uploads these mirrored assets in the
`build-scripts/mirroring` directory. Although there is no UI the general paths
to fetch releases from are:

- `/mirror/openssl/<openssl-version>/openssl.tar.gz`
- `/mirror/nginx/<nginx-version>/nginx.tar.gz`

Along with these assets we also distribute the original signatures we used to
validate these assets (*note: because these are legacy builds there is a high
chance the signatures are expired, but we choose to preserve the
original signatures*), to get the signatures just add `.asc` to the end of the
paths so you end up with:

- `/mirror/openssl/<openssl-version>/openssl.tar.gz.asc`
- `/mirror/nginx/<nginx-version>/nginx.tar.gz.asc`

We also upload hashes for every single file specifically we upload sha256,
sha512, and b2 sums (add `.sha256`/`.sha512`/`.b2` to any of the files to get
the hash of the file). We also *do* enforce HTTPS on the domain, to ensure no
one gets in your way while downloading assets.

The rough concept of building is running the configure (with enable-ssl2 &
enable-ssl3 and a few other options needed for nginx -- see the build scripts),
and then running make.

### Packaging ###

We use the `nFPM` packager: https://github.com/goreleaser/nfpm to build our
packages, so if you don't want to run the `make install` action, simply run:
`./build-scripts/packaging/package.sh`, and it'll build the specified version
it knows how to package.

Most of the packaging script can just be changed by changing the version
numbers, but you should confirm that the internal install scripts have not
changed.
