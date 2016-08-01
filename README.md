http://ruby-gem-downloads-badge.herokuapp.com/ - gem downloads shields
======================================================================

<!-- [![Dependency Status](https://gemnasium.com/bogdanRada/ruby-gem-downloads-badge.svg)](https://gemnasium.com/bogdanRada/ruby-gem-downloads-badge)  -->

[![Inline docs](http://inch-ci.org/github/bogdanRada/ruby-gem-downloads-badge.svg?branch=master)](http://inch-ci.org/github/bogdanRada/ruby-gem-downloads-badge) [![Code Climate](https://codeclimate.com/github/bogdanRada/ruby-gem-downloads-badge/badges/gpa.svg)](https://codeclimate.com/github/bogdanRada/ruby-gem-downloads-badge) [![Analytics](https://ga-beacon.appspot.com/UA-72570203-1/bogdanRada/ruby-gem-downloads-badge)](https://github.com/bogdanRada/ruby-gem-downloads-badge)

Clean and simple gem download badge, [courtesy of shields.io](https://github.com/badges/shields), that displays the downloads number of your gem. By default will display the downloads count of the latest version of the gem provided.


NEW Improvements added:
-------------------------------------------------------------------------------------
- if [shields.io](https://github.com/badges/shields) is unavailable , instead of showing a blank image,
we added support for rendering SVG and PNG badges that will be used only if the service is down ( this is done by checking if the status code returned is different than 200 or if the content type returned is text/html, which happens when the service returns a maintenance page )
- This solves the problem of not being able to render badges when shields.io is down.
- Currently this service supports only SVG, PNG and JSON format
- **The JSON format though will not display a badge but the data received from rubygems.org in JSON format**

##Use

In your README.md, just add an image with the base URL (`http://ruby-gem-downloads-badge.herokuapp.com/`) followed by the gem name and the version, for example :

You will then get a nice and pretty **SVG** with the downloads count of the gem provided:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails)

Or you can use any extension you like like this (e.g. **PNG**, **JSON**\):

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?extension=png)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?extension=png)

You can also specify the version of the gem, for example:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0)

You can also specify to display the total downloads count like this:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=total)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=total)

You can also specify to display the total downloads count for a version like this:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0?type=total)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.0?type=total)

You can also customize the message displayed when using **type=total** params by using this:

```ruby
  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=total&total_label=total-awesome)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?type=total&total_label=total-awesome)

If you want the downloads count to use **metrics**,, you can add `&metric=true` at the end of the url.

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?metric=true)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?metric=true)

That's it!

###Further Customization

If you want to change the color of your badge, just append `&color=COLOR_NAME` to the image URL. By default, the badge is blue.

Available colors are (gem is rails):

|    Color    |                                         Badge                                         |
|:-----------:|:-------------------------------------------------------------------------------------:|
| brightgreen | ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=brightgreen&style=flat) |
|    green    |    ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=green&style=flat)    |
| yellowgreen | ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=yellowgreen&style=flat) |
|   yellow    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=yellow&style=flat)    |
|   orange    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=orange&style=flat)    |
|     red     |     ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=red&style=flat)     |
|  lightgray  |  ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=lightgray&style=flat)  |
|    blue     |    ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=blue&style=flat)     |
|   ff69b4    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?color=ff69b4&style=flat)    |

If you want to style of the badge just append `&style=STYLE_NAME`.to the image URL. By default, the badge is **flat**

Available styles are:

| Style Name  |                                   Badge                                    |
|:-----------:|:--------------------------------------------------------------------------:|
|    flat     |    ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=flat)     |
|   plastic   |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=plastic)   |
| flat-square | ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=flat-square) |
|   social    |   ![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=social)    |

For social badges you can also use links for both sides of the badge like this:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=social&link=http://google.com&link=http://yahoo.com)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?style=social&link=http://google.com&link=http://yahoo.com)

If you want something else written on the badge you can use:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?label=something-else)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?label=something-else)

You can change the logo width by using this:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails?logoWidth=80)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails?logoWidth=80)

If you specify a version that is not valid like this, you will see a invalid image:

```ruby
![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.dsad)
```

![](http://ruby-gem-downloads-badge.herokuapp.com/rails/4.1.dsad)

---

**This repository was created by bogdanRada - but is completely built off of [shields.io](http://github.com/badges/shields) - go check them out! Having a problem? [Open an issue.](http://github.com/bogdanRada/gem-downloads-badge/issues)**
