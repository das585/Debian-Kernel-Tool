# Debian Kernel Tool

A tool for building a custom linux kernel for Debian-based distros. This started with only the make and install commands, but turned into more of a walk-through of the building process to automate repetitive tasks. Feel free to change this script up to fit your needs.

## Basic usage:

Run the script with:

     `$ ./kernel_tool.sh <kernelVersion>(optional)`

Where `kernelVersion` is a **_6.x.x_** kernel version. If provided and different from the version found in the script's directory, the given kernel version will be downloaded and built. Otherwise, if there is another kernel source present, that will be built.

When using this script initially, a _kernel_ directory will be created one level above the script (ie the same level as the directory the script is in). This is to house the install files created by building the kernel. In addition, an _old_ directory is created within the _kernel_ directory. This is to house any old builds that you wish to retain. The script copies itself into the newly created directory structure as the new place to build kernels from.

While running, follow the prompts along the way to complete the build process. Reboot at the end for the new kernel to be applied.


## Misc

I will periodically be updating this script as I think of more useful (at least to me) automations or bugs that need to be fixed up. For the most part, this is just a starting place for others to create a kernel build script off of if they so desire.

My knowledge of bash scripting is fairly basic, so I also used this project to learn more about different functionality and the like within bash scripts.

Hopefully this proves to be useful in helping someone get started on their kernel customization journey. Here's a link to [kernel.org](https://kernel.org) to get you started on finding and installing the most recent kernel version. That's all folks!
