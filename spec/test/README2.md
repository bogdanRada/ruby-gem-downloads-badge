This page is used only for testing. Please do not use any of these urls in your README files!!!!
================================================================================================

Clean and simple gem download badge, [courtesy of shields.io](https://github.com/badges/shields), that displays the downloads number of your gem. By default will display the downloads count of the latest version of the gem provided.

##Use In your README.md, just add an image with the base URL (`http://ruby-gem-test2.herokuapp.com/`) followed by the gem name and the version, for example :

You will then get a nice and pretty SVG with the downloads count of the gem provided:

```
  ![](http://ruby-gem-test2.herokuapp.com/rails)
```

![](http://ruby-gem-test2.herokuapp.com/rails)

Or you can use any extension you like like this:

```
   ![](http://ruby-gem-test2.herokuapp.com/rails?extension=png)
```

![](http://ruby-gem-test2.herokuapp.com/rails?extension=png)

You can also specify the version of the gem, for example:

```
  ![](http://ruby-gem-test2.herokuapp.com/rails/4.1.0)
```

![](http://ruby-gem-test2.herokuapp.com/rails/4.1.0)

You can also specify to display the total downloads count like this:

```
  ![](http://ruby-gem-test2.herokuapp.com/rails?type=total)
```

![](http://ruby-gem-test2.herokuapp.com/rails?type=total)

You can also specify to display the total downloads count for a version like this:

```
  ![](http://ruby-gem-test2.herokuapp.com/rails/4.1.0?type=total)
```

![](http://ruby-gem-test2.herokuapp.com/rails/4.1.0?type=total)

If you want a flat image, you can add `&style=flat` at the end of the url.

```
![](http://ruby-gem-test2.herokuapp.com/rails?style=flat)
```

![](http://ruby-gem-test2.herokuapp.com/rails?style=flat)

If you want the downloads count to use metrics,, you can add `&metric=true` at the end of the url.

```
![](http://ruby-gem-test2.herokuapp.com/rails?metric=true)
```

![](http://ruby-gem-test2.herokuapp.com/rails?metric=true)

That's it!

###Further Customization

If you want to change the color of your badge, just append `&color=COLOR_NAME` to the image URL. By default, the badge is blue.

Available colors are (gem is rails):

|    Color    |                                    Badge                                    |
|:-----------:|:---------------------------------------------------------------------------:|
| brightgreen | ![](http://ruby-gem-test2.herokuapp.com/rails?color=brightgreen&style=flat) |
|    green    |    ![](http://ruby-gem-test2.herokuapp.com/rails?color=green&style=flat)    |
| yellowgreen | ![](http://ruby-gem-test2.herokuapp.com/rails?color=yellowgreen&style=flat) |
|   yellow    |   ![](http://ruby-gem-test2.herokuapp.com/rails?color=yellow&style=flat)    |
|   orange    |   ![](http://ruby-gem-test2.herokuapp.com/rails?color=orange&style=flat)    |
|     red     |     ![](http://ruby-gem-test2.herokuapp.com/rails?color=red&style=flat)     |
|  lightgray  |  ![](http://ruby-gem-test2.herokuapp.com/rails?color=lightgray&style=flat)  |
|    blue     |    ![](http://ruby-gem-test2.herokuapp.com/rails?color=blue&style=flat)     |
|   ff69b4    |   ![](http://ruby-gem-test2.herokuapp.com/rails?color=ff69b4&style=flat)    |

If you want something else written on the badge you can use:

```
![](http://ruby-gem-test2.herokuapp.com/rails?label=something-else)
```

![](http://ruby-gem-test2.herokuapp.com/rails?label=something-else)

If you specify a version that is not valid like this, you will see a invalid image:

```
![](http://ruby-gem-test2.herokuapp.com/rails/4.1.dsad)
```

![](http://ruby-gem-test2.herokuapp.com/rails/4.1.dsad)

---

**This repository was created by bogdanRada - but is completely built off of [shields.io](http://github.com/badges/shields) - go check them out! Having a problem? [Open an issue.](http://github.com/bogdanRada/gem-downloads-badge/issues)**
