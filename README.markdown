# SCGID - An SCGI client for D (Alpha)
This library allows you to create a server in D that can listen/respond to SCGI requests. A usage example is available in src/example.d

## How to run
Compile the code, setup apache, run the server and visit the page using a web browser. Instructions are given below.

### Compilation Instructions
	dmd -O -inline src/example.d src/scgi.d

### Setting up a WebServer
Most well-known webservers support SCGI out of the box (ex: Apache) or via 3rd party plugins (ex: Nginx). In both cases, the server is responsible for parsing an incoming HTTP request and converting it into a valid SCGI request. This client reads that request and provides you with a simple API to access server/request variables. Here i have documented how to setup Apache, most other webservers should be as easy.

#### Setting up Apache
Official Link : http://httpd.apache.org/docs/2.3/mod/mod_proxy_scgi.html . You need to enable "mod_proxy_scgi" and setup a "ProxyPass" in your virtual host. The following are the simplest steps :

-	Link (or copy) proxy.load and proxy_scgi.load to the mods-enabled folder.
	In Ubuntu :	

		sudo ln -s /etc/apache2/mods-available/proxy* /etc/apache2/mods-enabled/
	
-	Add ProxyPass to your VirtualHost, like so :
	ProxyPass /any_path/ scgi://url:port/
	ex: 

		ProxyPass /scgi-bin/ scgi://localhost:4444/
	
- 	Restart Apache.
	In Ubuntu : 

		sudo /etc/init.d/apache2 restart
	
### Run SCGI
Now start your server on the same port you configured Apache with:

	./example 4444
	<Listening on port 4444.>

Your server is now connected and ready to receieve requests. Visit http://localhost/scgi-bin/ to see it in action.

## Code Example:
Its only one line of code!

	SCGIServer(int port, function void(const Request request, Socket connection){
		//Your code goes here
	})

See src/example.d


## About this project
I wrote this library in a few hours over the weekend because i couldn't find a D library for SCGI. One of the reasons this library is so small is because the SCGI protocol itself is so simple (http://www.python.ca/scgi/protocol.txt). Currently this library is single threaded.
This work is still Alpha, i have a lot more planned to make this into something production worthy.


## Benchmarks
I ran some ab (Apache Bench) tests to get a feel of some performance. Here are the numbers after 3 tests:
<pre>
	ab -c100 -n10000 http://localhost/scgi-bin/

	Concurrency Level:      100  
	Time taken for tests:   6.173 seconds  
	Complete requests:      10000  
	Failed requests:        0  
	Write errors:           0  
	Requests per second:    1619.99 [#/sec] (mean)  
	Time per request:       0.617 [ms] (mean, across all concurrent requests)  
	Transfer rate:          1913.36 [Kbytes/sec] received  
	
	Connection Times (ms)  
	              min  mean[+/-sd] median   max  
	Connect:        0    0   0.6      0       7  
	Processing:     3   35 109.0     30    3037  
	Waiting:        3   35 109.0     29    3037  
	Total:         11   35 108.9     30    3037  
</pre>

I ran this on an Intel Core i3 2.13Ghz, 4GB Ram and Ubuntu 11.04 x64.


## D Compiler
Tested only with dmd 2.058 on Ubuntu x64. 


## Contributing to this project
Please download and play with this project. Any thoughts on how to improve the code, documentation, performance and anything else is very welcome. 
Open tickets for bugs, or pull requests for fixes.


Thanks!   
Adil Baig  
Twitter : @aidezigns