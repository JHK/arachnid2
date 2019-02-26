# Arachnid2

## About

Arachnid2 is a simple, fast web-crawler written in Ruby.
You can use [typhoeus](https://github.com/typhoeus/typhoeus)
to get HTTP requests, or [Watir](https://github.com/watir/watir)
to render pages.

[bloomfilter-rb](https://github.com/igrigorik/bloomfilter-rb)
stores the URLs it will get and has gotten,
and [nokogiri](https://github.com/sparklemotion/nokogiri)
to find the URLs on each webpage, adding them to the bloomfilter queue.

Arachnid2 is a successor to [Arachnid](https://github.com/dchuk/Arachnid),
and was abstracted out of the [Tellurion Bot](https://github.com/samnissen/tellurion_bot).

## Usage

### Typheous (cURL)

The basic use of Arachnid2 is surfacing the responses from a domains'
URLs by visiting a URL, collecting any links to the same domain
on that page, and visiting those to do the same.

Hence, the simplest output would be to collect all of the responses
while spidering from some URL.

```ruby
require "arachnid2"

url = "http://www.maximumfun.org"
spider = Arachnid2.new(url)
responses = []

spider.crawl { |response|
  responses << response
}
```

Obviously this could become unwieldy,
so you can execute logic within the spidering to collect a narrow subset
of the responses, transform or dissect the response,
or both (or whatever you want).

```ruby
require "arachnid2"
require "nokogiri"

url = "https://daringfireball.net"
spider = Arachnid2.new(url)
responses = []

spider.crawl { |response|
  responses << Nokogiri::HTML(response.body) if response.effective_url =~ /.*amazon.*/
  print '*'
}
```

`Arachnid2#crawl` will return always `nil`.

#### Options

```ruby
require "arachnid2"

url = "http://sixcolours.com"
spider = Arachnid2.new(url)
opts = {
  followlocation: true,
  timeout: 300,
  time_box: 60,
  max_urls: 50,
  :headers => {
    'Accept-Language' => "en-UK",
    'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0",
  },
  memory_limit: 89.99,
  proxy: {
    ip: "1.2.3.4",
    port: "1234",
    username: "sam",
    password: "coolcoolcool",
  }
  :non_html_extensions => {
    3 => [".abc", ".xyz"],
    4 => [".abcd"],
    6 => [".abcdef"],
    11 => [".abcdefghijk"]
  }
}
responses = []

spider.crawl(opts) { |response|
  responses << response
}
```

##### `followlocation`

Tell Typhoeus to follow redirections.

##### `timeout`

Tell Typheous or Watir how long to wait for page load.

##### `time_box`

The crawler will time-bound your spidering.
If no valid integer is provided,
it will crawl for 15 seconds before exiting.
10000 seconds is the current maximum,
and any value above it will be reduced to 10000.

##### `max_urls`

The crawler will crawl a limited number of URLs before stopping.
If no valid integer is provided,
it will crawl for 50 URLs before exiting.
10000 seconds is the current maximum,
and any value above it will be reduced to 10000.

##### `headers`

This is a hash that represents any HTTP header key/value pairs you desire,
and is passed directly to Typheous. Before it is sent, a default
language and user agent are created:

###### Defaults

The HTTP header `Accept-Language` default is
`en-IE, en-UK;q=0.9, en-NL;q=0.8, en-MT;q=0.7, en-LU;q=0.6, en;q=0.5, \*;0.4`

The HTTP header `User-Agent` default is
`Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1 Safari/605.1.15`

##### `proxy`

Provide your IP, port for a proxy. If required, provide credentials for
authenticating to that proxy. Proxy options and handling are done
by Typhoeus.

##### `non_html_extensions`

This is the list of TLDs to ignore when collecting URLs from the page.
The extensions are formatted as a hash of key/value pairs, where the value
is an array of TLDs, and the keys represent the length of those TLDs.

##### `memory_limit` and Docker

In case you are operating the crawler within a container, Arachnid2
can attempt to prevent the container from running out of memory.
By default, it will end the crawl when the container uses >= 80%
of its available memory. You can override this with the
option.

##### Non-HTML links

The crawler attempts to stop itself from returning data from
links that are not indicative of HTML, as detailed in
`Arachnid2::NON_HTML_EXTENSIONS`.

#### Caching (optional)

If you have setup a cache to deduplicate crawls,
set a cached service url
`export ARACHNID_CACHED_SERVICE_ADDRESS=http://localhost:9000`

This expects a push and get JSON API to respond
to `/typhoeus_responses`, with a URL and the options pushed
exactly as received as parameters. It will push any crawls
to the service, and re-use any crawled pages
if they are found to match.

### With Watir

Crawling with Watir works similarly, but requires you setup your
environment for Watir, and headless web browsing if required.
See the Watir documentation for more information.

```ruby
# ...
Arachnid2.new(url).crawl_watir(opts)
# -or-
with_watir = true
Arachnid2.new(url).crawl(opts, with_watir)
```

#### Options

See the Typhoeus options above &mdash; most apply to Watir as well, with
some exceptions:

##### `proxy`

Watir proxy options are formatted differently:

```ruby
proxy: {
  http: "troy.show:8080",
  ssl: "abed.show:8080"
},
```

Proxy options handling is done by Watir.

##### `headless`

And it accepts an argument to make browse headlessly

```ruby
opts = { headless: true }
```

##### `followlocation` and `max_concurrency`

These options do not apply to Watir, and will be ignored.

## Development

Fork the repo and run the tests

```ruby
bundle exec rspec spec/
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/samnissen/arachnid2.
This project is intended to be a safe,
welcoming space for collaboration,
and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Arachnid2 project’s codebases,
issue trackers, chat rooms and mailing lists is expected
to follow the
[code of conduct](https://github.com/samnissen/arachnid2/blob/master/CODE_OF_CONDUCT.md).
