#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;
import bodyaccess;
import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {
    /**
     * Happens before we check if we have this in cache already.
     *
     * Typically you clean up the request here, removing cookies you don't need,
     * rewriting the request, etc.
     */

    std.log("[VARNISH] RECV: " + req.method + " - " + req.http.host + req.url);

    if (req.method == "POST" || req.method == "PUT") {
        # save the method request.  we´ll need to recover this later since varnish will
        # convert everything back to get
        set req.http.x-method = req.method;
        std.log("[VARNISH] RECV: setting req.http.x-method to '" + req.method  + "'");

        # buffering the req.body is mandatory
        std.cache_req_body(110KB);
        # here you filter for content that might be malicious in the req body
        set req.http.x-len = bodyaccess.len_req_body();
        set req.http.x-re = bodyaccess.rematch_req_body("I'm a malicious req.body");

        # check if the req.body is malicious
        if (std.integer(req.http.x-len, 0) > 10000 && std.integer(req.http.x-re, 0) == 1) {
            # return an error because the req.body is not trusted
            return (synth(400, "bad request"));
        }
    }
    return (hash);
}

sub vcl_hash {
  /* hash on request body, the very first incoming request will be a miss */
  /* once the request body is available in the cache we will get hits */

  std.log("[VARNISH] HASH: hashing req.url - " + req.url);
  std.log("[VARNISH] HASH: hashing req.method - " + req.method);
  std.log("[VARNISH] HASH: hashing req.body - " + req.http.body);
  hash_data(req.url);
  hash_data(req.method);
  bodyaccess.hash_req_body();
  return (lookup);
}

sub vcl_backend_response {
    /**
     * Happens after we have read the response headers from the backend.
     *
     * Here you clean the response headers, removing silly Set-Cookie headers
     * and other mistakes your backend does.
     */
}

sub vcl_backend_fetch {
    /**
     * Called before sending the backend request. In this subroutine you typically
     * alter the request before it gets to the backend.
     */

    # here we recover the req.method we saved previously inside of vcl_hash
    # varnish will try to send a GET request to the backend but we force the use
    # of POST/PUT methods on the backend side
    set bereq.method = bereq.http.x-method;
}

sub vcl_deliver {
    /**
     * Happens when we have all the pieces we need, and are about to send the
     * response to the client.
     *
     * You can do accounting or modifying the final object here.
     */

    set resp.http.x-re = req.http.x-re;
    set resp.http.x-len = req.http.x-len;
    std.log("[VARNISH] DELIVER: resp.status: " + resp.status);
    std.log("[VARNISH] DELIVER: resp.message: " + resp.reason);
    std.log("[VARNISH] DELIVER: resp.http.body: " + resp.http.body);
    std.log("[VARNISH] DELIVER: resp.http.x-len: " + resp.http.x-len);
    std.log("[VARNISH] DELIVER: resp.http.x-re: " + resp.http.x-re);

    # send some handy statistics back, useful for checking cache
    if (obj.hits > 0) {
        set resp.http.X-Cache-Action = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
        std.log("[VARNISH] DELIVER: CACHE HIT");
        std.log("[VARNISH] DELIVER: CACHE HITS (" + obj.hits + ")");
    }
    else {
        set resp.http.X-Cache-Action = "MISS";
        std.log("[VARNISH] DELIVER: CACHE MISS");
    }
    std.log("[VARNISH] ---------------------------------------------");
}
