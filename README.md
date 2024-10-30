
# android_kernel_tools-build
## Tool for building the Android Kernel (Pre-GKI)
## Features

- Build Android kernel (Pre-5.4)
- Support multiple compilers (GCC based only for now)
- Build in clean or dirty mode
- Pack boot.img for you (Optional)
- Written in bash at 3AM




## Example Usage

```bash
./init.sh -b device -m clean -t gcc -e
```
## Documentation
The script is pretty documented already if you read it, its fairly simple, all you need to do is set the required variables in ./config.sh file according to your device.
- For usage documentation: ./init.sh -h


## Dependencies
- gcc, ccache, bash, linux
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

