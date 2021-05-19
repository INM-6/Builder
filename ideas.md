# Avoid rebuild if build is there

## What do we encounter
When `build software version` is called
* first barrier: acceptance of configured and build variables --> enter
* if location already exists:
	* ask if we should delete or not

## What we need to introduce
* silent mode:
	build -s
	* does not need interaction with user
	* exists if file already exists
* force mode:
	build -f
	* delete and rebuild


