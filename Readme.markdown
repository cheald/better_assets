Better Assets is a monkeypatch to the Rails 2.3.2 AssetTagHelper to enable some additional functionality. The key points are:

* Time-based expiry of cached asset files, which is primarily useful for...
* Caching and combining of remote assets
* Finally, you can post-process combined assets with blocks passed to `javascript_include_tag` and `stylesheet_link_tag`.

## Examples

It's easy. You use it just like normal:

`<%=javascript_include_tag("jquery-1.3.2", "foo", :cache => "all") {|text| Packr.pack(text, :base62 => true) } %>`

Whoa! What is this block madness? Why, that's an extension to allow you to do whatever you want. In this example, we're using [jcoglan's Packr library](http://blog.jcoglan.com/2009/02/22/packr-31-improved-compression-and-private-variable-support/) to automatically pack our generated Javascript. This can result in filesize being reduced by pretty massive amounts, and will result in appreciable performance benefits.

Well, that's all fine and dandy, but it's not my combined Javascript that's killing me, it's all those pesky DNS lookups for all my widget code and CSS. Never fear, you're covered there, too.

`<%=javascript_include_tag(
  "http://rpxnow.com/openid/v2/widget",
  "http://partner.googleadservices.com/gampad/google_service.js",
  "http://s3.amazonaws.com/getsatisfaction.com/feedback/feedback.js",
  "http://blippr.tags.crwdcntrl.net/cc.js",
  :cache => "remote", :lifetime => 12.hours) %>`
  
Madness! Sheer madness! All those remote Javascript files are sucked down, combined, and cached as "remote.js". It'll automatically expire after 12 hours, and be re-cached after that. That way, you can get all the performance benefits of serving a single combined JS file without having to stress out that someone over at WidgetHeadquarters is going to change a piece of code and completely screw you over until you notice that your local Javascript file doesn't match theirs six weeks later.

This, oddly enough, works for CSS files, too.

`<%=stylesheet_link_tag(
  "http://s3.amazonaws.com/getsatisfaction.com/feedback/feedback.css",
  "http://s3.amazonaws.com/getsatisfaction.com/feedback/widget.css",
  :cache => "remote", :lifetime => 12.hours
) %>`

No more stalling out at requests to Amazon's S3 for CSS files! No more extraneous DNS requests or HTTP connections! No fuss, no muss, no headaches for you or you user.

All this, and it makes crispy bacon, too.*

To get it, just...wait for it. Very complex procedure ahead:

  script/plugin install git://github.com/cheald/better_assets.git 
  
Restart your app, and that's it. Your assets are now approximately 163% more awesome, while being leaner and looking better in that fabulous summer swimsuit at the same time.

Score.










\* Not really.