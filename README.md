# VISP Documentation

### vpImageIo & vpDisplay
Read/write images with various image format.
```c++
#include <visp3/io/vpImageIo.h>
#include <visp3/gui/vpDisplayOpenCV.h>
vpImage<vpRGBa> I;
vpImageIo::read(I, "monkey.jpeg");
vpImageIo::write(I, "monkey.png");
vpDisplayOpenCV d(I, vpDisplay::SCALE_AUTO);
vpDisplay::display(I);
```


docker run --gpus all -p 9080:9080 -v /etc/localtime:/etc/localtime:ro --rm -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -e http_proxy -e https_proxy -e ftp_proxy -e LIBGL_ALWAYS_SOFTWARE=1 -v `pwd`/:/unified_runtime visp bash