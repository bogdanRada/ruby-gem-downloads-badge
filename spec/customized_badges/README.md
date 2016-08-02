This page is used only for testing. Please do not use any of these urls in your README files!!!!
================================================================================================

Clean and simple gem download badge, [courtesy of shields.io](https://github.com/badges/shields), that displays the downloads number of your gem. By default will display the downloads count of the latest version of the gem provided.

##Use

In your README.md, just add an image with the base URL (`http://ruby-gem-downloads-badge.herokuapp.com//`) followed by the gem name and the version, for example :

You will then get a nice and pretty **SVG** with the downloads count of the gem provided:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?customized_badge=true)

Or you can use any extension you like like this (e.g. **PNG**, **JSON**\):

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?extension=png&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?extension=png&customized_badge=true)

You can also specify the version of the gem, for example:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0?customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0?customized_badge=true)

You can also specify to display the total downloads count like this:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=tota&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=total&customized_badge=true)

You can also specify to display the total downloads count for a version like this:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0?type=total&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0?type=total&customized_badge=true)

You can also customize the message displayed when using **type=total** params by using this:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=total&total_label=total-awesome&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=total&total_label=total-awesome&customized_badge=true)

If you want the downloads count to use **metrics**,, you can add `&metric=true` at the end of the url.

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?metric=true&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?metric=true&customized_badge=true)

That's it!

###Further Customization

If you want to change the color of your badge, just append `&color=COLOR_NAME` to the image URL. By default, the badge is blue.

Available colors are (gem is rails):

|    Color    |                                         Badge                                         |
|:-----------:|:-------------------------------------------------------------------------------------:|
| brightgreen | ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=brightgreen&style=flat&customized_badge=true) |
|    green    |    ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=green&style=flat&customized_badge=true) |
| yellowgreen | ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=yellowgreen&style=flat&customized_badge=true) |
|   yellow    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=yellow&style=flat&customized_badge=true) |
|   orange    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=orange&style=flat&customized_badge=true) |
|     red     |     ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=red&style=flat&customized_badge=true) |
|  lightgray  |  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=lightgray&style=flat&customized_badge=true) |
|    blue     |    ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=blue&style=flat&customized_badge=true) |
|   ff69b4    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=ff69b4&style=flat&customized_badge=true) |

If you want to style of the badge just append `&style=STYLE_NAME`.to the image URL. By default, the badge is **flat**

Available styles are:

| Style Name  |                                   Badge                                    |
|:-----------:|:--------------------------------------------------------------------------:|
|    flat     |    ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=flat&customized_badge=true)     |
|   plastic   |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=plastic&customized_badge=true)   |
| flat-square | ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=flat-square&customized_badge=true) |
|   social    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=social&customized_badge=true)    |

For social badges you can also use links for both sides of the badge like this:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=social&link=http://google.com&link=http://yahoo.com&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=social&link=http://google.com&link=http://yahoo.com&customized_badge=true)

If you want something else written on the badge you can use:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?label=something-else&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?label=something-else&customized_badge=true)

You can change the logo width by using this:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?logoWidth=80&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?logoWidth=80&customized_badge=true)

If you specify a version that is not valid like this, you will see a invalid image:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.dsad&customized_badge=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.dsad&customized_badge=true)

---

**This repository was created by bogdanRada - but is completely built off of [shields.io](http://github.com/badges/shields) - go check them out! Having a problem? [Open an issue.](http://github.com/bogdanRada/gem-downloads-badge/issues)**
