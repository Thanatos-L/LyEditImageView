# LyEditImageView

```
An view for zoom, pan, rotate and crop image built by swift in single file.
```
## Preview
Pan Crop View

![1](https://github.com/Thanatos-L/Playground/tree/master/LyEditImageView/readme/1.gif)


Zoom, Rotate and Crop Image

![2](https://github.com/Thanatos-L/Playground/tree/master/LyEditImageView/readme/2.gif)

## Quick Start

To add a LyEditImageView in your viewController:
```
let editView = LyEditImageView(frame: frame)
let image = yourimage
editView.initWithImage(image: yourimage)
self.yourview.addSubview(editView)
```

Then get the cropped image:
```
let croppedImage = editView.getCroppedImage()

```
## For Who can speak Mandarin

[iOS - 图片的平移，缩放，旋转和裁剪](http://www.jianshu.com/p/fbe503234e35)

## License
LyEditImageView is released under the MIT License.
