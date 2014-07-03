http://ruby-badge.herokuapp.com/ - gem downloads shields
=============
Clean and simple gem download badge, [courtesy of shields.io](https://github.com/badges/shields), that displays the downloads number of your gem.
By default will display the downloads count of the latest version of the gem provided. 

##Use
In your README.md, just add an image with the base URL (`http://ruby-badge.herokuapp.com/`) with a argument "gem" with the name of the gem, for example :
 
You will then get a nice and pretty SVG with the downloads count of the gem  provided:

```
  ![](https://ruby-badge.herokuapp.com/rails)
```
 ![](https://ruby-badge.herokuapp.com/rails)

You can also specify  the version of the gem, for example: 
```
  ![](https://ruby-badge.herokuapp.com/rails/4.1.0)
```
![](https://ruby-badge.herokuapp.com/rails/4.1.0)

You can also specify to display the total downloads count like this:

```
  ![](https://ruby-badge.herokuapp.com/rails?type=total)
```

 ![](https://ruby-badge.herokuapp.com/rails?type=total)

You can also specify to display the total downloads count for a version like this:
```
  ![](https://ruby-badge.herokuapp.com/rails/4.1.0?type=total)
```

 ![](https://ruby-badge.herokuapp.com/rails/4.1.0?type=total)



If you want a flat image, you can add `&style=flat` at the end of the url.

```
![](https://ruby-badge.herokuapp.com/rails?style=flat)
```

![](https://ruby-badge.herokuapp.com/rails?style=flat)

That's it!

###Further Customization

If you want to change the color of your badge, just append `&color=COLOR_NAME` to the image URL.  By default, the badge is blue.

Available colors are (gem is rails):

| Color         | Badge                                                                           |
|:-------------:|:-------------------------------------------------------------------------------:|
| brightgreen   | ![](https://ruby-badge.herokuapp.com/rails?color=brightgreen&style=flat) |
| green         | ![](https://ruby-badge.herokuapp.com/rails?color=green&style=flat)       |
| yellowgreen   | ![](https://ruby-badge.herokuapp.com/rails?color=yellowgreen&style=flat) |
| yellow        | ![](https://ruby-badge.herokuapp.com/rails?color=yellow&style=flat)      |
| orange        | ![](https://ruby-badge.herokuapp.com/rails?color=orange&style=flat)      |
| red           | ![](https://ruby-badge.herokuapp.com/rails?color=red&style=flat)         |
| lightgray     | ![](https://ruby-badge.herokuapp.com/rails?color=lightgray&style=flat)   |
| blue          | ![](https://ruby-badge.herokuapp.com/rails?color=blue&style=flat)        |
| ff69b4        | ![](https://ruby-badge.herokuapp.com/rails?color=ff69b4&style=flat)      |


If you specify a version that is not valid like this, you will see a invalid image: 

```
![](https://ruby-badge.herokuapp.com/rails/4.1.dsad)
```
 
 ![](https://ruby-badge.herokuapp.com/rails/4.1.dsad)

------

**This repository was created by bogdanRada - but is completely built off of [shields.io](https://github.com/badges/shields) - go check them out!  Having a problem?  [Open an issue.](https://github.com/bogdanRada/gem-downloads-badge/issues)**
