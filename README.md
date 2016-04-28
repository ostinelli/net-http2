[![Build Status](https://travis-ci.org/ostinelli/net-http2.svg?branch=master)](https://travis-ci.org/ostinelli/net-http2)

# NetHttp2

NetHttp2 is an HTTP2 client for Ruby.


## Installation
Just install the gem:

```
$ gem install net-http2
```

Or add it to your Gemfile:

```ruby
gem 'net-http2'
```

## Usage

With a blocking call:
```ruby
require 'net-http2'

# create a client
client = NetHttp2::Client.new(uri: "http://106.186.112.116")

# send request
response = client.get('/')

# read the response
response.ok?      # => true
response.status   # => '200'
response.headers  # => {":status"=>"200"}
response.body     # => "A body"

# close the connection
client.close
```

With a non-blocking call:
```ruby
require 'net-http2'

# create a client
client = NetHttp2::Client.new(uri: "http://106.186.112.116")

# send request
client.async_get('/') do |response|

  # read the response
  p response.ok?      # => true
  p response.status   # => '200'
  p response.headers  # => {":status"=>"200"}
  p response.body     # => "A body"

  # close the connection
  client.close
end

# quick & dirty fix to wait for the block to be called asynchronously
sleep 5
```


## Objects

### `NetHttp2::Client`
To create a new client:

```ruby
NetHttp2::Client.new(uri)
```

#### Methods

 * **new(uri, options={})** → **`NetHttp2::Client`**
 Returns w new client. `uri` is a `string` such as https://localhost:443.
 The only current option is `:ssl_context`, in case the uri has an https scheme and you want your SSL client to use a custom context.

 For instance:

  ```ruby
  certificate = File.read("cert.pem")
  ctx         = OpenSSL::SSL::SSLContext.new
  ctx.key     = OpenSSL::PKey::RSA.new(certificate, "cert_password")
  ctx.cert    = OpenSSL::X509::Certificate.new(certificate)

  NetHttp2::Client.new(uri, ssl_context: ctx)
  ```

 * **uri** → **`URI`**
 Returns the URI of the APNS endpoint.

 * **get(path, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a GET request. This is a blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.

  For example:

  ```ruby
  response_1 = client.get('/path1')
  response_2 = client.get('/path2', { 'x-custom-header' => 'custom' })
  response_3 = client.get('/path3', { 'x-custom-header' => 'custom' }, timeout: 1)
  ```

 * **post(path, body, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a POST request. This is a blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.

 * **put(path, body, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a PUT request. This is a blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.

 * **delete(path, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a DELETE request. This is a blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.

 * **async_get(path, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a GET request. This is a non-blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.

  For example:

  ```ruby
  client.get('/path1') { |response_1| p response_2 }
  client.get('/path2', { 'x-custom-header' => 'custom' }) { |response_2| p response_2 }
  client.get('/path3', {}, timeout: 1) { |response_3| p response_3 }
  ```

 * **async_post(path, body, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a POST request. This is a non-blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.

 * **async_put(path,body, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a PUT request. This is a non-blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.

 * **async_delete(path, headers={}, options={})** → **`NetHttp2::Response` or `nil`**
 Sends a DELETE request. This is a non-blocking call. Options can only specify a `:timeout` (defaults to 60).
 Returns `nil` in case a timeout occurs.


### `NetHttp2::Response`

#### Methods

 * **ok?** → **`boolean`**
 Returns if the request was successful.

 * **headers** → **`hash`**
 Returns a Hash containing the Headers of the response.

 * **status** → **`string`**
 Returns the status code.

 * **body** → **`string`**
 Returns the RAW body of the response.


## Contributing
So you want to contribute? That's great! Please follow the guidelines below. It will make it easier to get merged in.

Before implementing a new feature, please submit a ticket to discuss what you intend to do. Your feature might already be in the works, or an alternative implementation might have already been discussed.

Do not commit to master in your fork. Provide a clean branch without merge commits. Every pull request should have its own topic branch. In this way, every additional adjustments to the original pull request might be done easily, and squashed with `git rebase -i`. The updated branch will be visible in the same pull request, so there will be no need to open new pull requests when there are changes to be applied.

Ensure to include proper testing. To run tests you simply have to be in the project's root directory and run:

```bash
$ rake
```
