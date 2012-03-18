import scgi, std.conv, std.stdio;

int main(string args[])
{
    if (args.length < 2)
    {
        writeln("./" ~ args[0] ~ " <PORT>");
        return 1;
    }
    
    auto port = to!ushort(args[1]);
    
    /**
       The following call will start the SCGI server on port "port" and go into and infinite loop.
    */
    SCGIServer(port, function void(const Request request, Socket connection){
        /*
           This function is called once per request. The Request struct contains the headers
           as well GET and POST variables (parsed and urldecoded). The Socket is the connection 
           to the client. Use connection.send("string") to send responses back to the client.
           You can close the connection, or the library will do it for you once the function completes.   
        */
        
        connection.send("Status: 200 OK\r\n\r\n");
        connection.send("Content-Type: text/html\r\n\r\n");

        connection.send("<h1>Headers</h1><ul>");
        foreach(k, v; request.headers)
            connection.send("<li><b>" ~ k ~ "</b> : " ~ v ~ "</li>");
        connection.send("</ul>");
        
        connection.send("<h1>GET</h1><ul>");
        foreach(k, v; request.get)
            connection.send("<li><b>" ~ k ~ "</b> : " ~ v ~ "</li>");
        connection.send("</ul>");
        
        connection.send("<h1>POST</h1><ul>");
        foreach(k, v; request.post)
            connection.send("<li><b>" ~ k ~ "</b> : " ~ v ~ "</li>");
        connection.send("</ul>");
        
        connection.send("<h1>Body " ~ to!string(request.content.length) ~ "</h1>");
        connection.send(request.content);
    });
        
    return 0;
}