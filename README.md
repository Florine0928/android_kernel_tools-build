
# android_linux_kernel_tools-build
## Tool for building the Linux Kernel and ACK 4.19<
## Features

- Build Android kernel (Pre-5.4)
- Build X86 Linux Kernel
- Support multiple compilers (GCC based only for now)
- Build in clean or dirty mode
- Pack boot.img for you (Optional)
- Install Linux Kernel for you (Optional)
- Written in bash at 3AM




## Example Usage

```bash
./init.sh -b device -m clean -t gcc -e 
./init.sh -b X86_64 -m clean -e grub -d
```
## Documentation
The script is pretty documented already if you read it, its fairly simple, all you need to do is set the required variables in ./config.sh file according to your device.



## Dependencies
- gcc, ccache, bash, linux, ncurses
## Installation


```bash
 git clone https://github.com/Florine0928/android_kernel_tools-build.git
 mv android_kernel_tools-build/* path-to-kernel/
```
    
## Acknowledgements

 - [osm0sis](https://github.com/osm0sis/Android-Image-Kitchen) - A.I.K
 - [ananjaser1211](https://github.com/ananjaser1211/Apollo/commits/Apollo/) - A.I.K Pack Boot.img Function, cool guy in fact
 - [readme.so](https://readme.so) - For cool readme




## License

[Apache Version 2.0](https://choosealicense.com/licenses/apache-2.0/)

