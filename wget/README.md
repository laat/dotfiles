# wget
wget from sourceforge is painful without this.

##content-disposition from the man page:
If this is set to on, experimental (not fully-functional) support for
Content-Disposition headers is enabled. This can currently result in extra
round-trips to the server for a HEAD request, and is known to suffer from a few
bugs, which is why it is not currently enabled by default.

This option is useful for some file-downloading CGI programs that use
Content-Disposition headers to describe what the name of a downloaded file
should be.
