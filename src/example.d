import scgi, std.conv, std.stdio;

int main(string args[])
{
    if (args.length < 2)
    {
        writeln("./" ~ args[0] ~ " <PORT>");
        return 1;
    }
    
    auto port = to!ushort(args[1]);
    
    SCGIServer(port, function void(const Request request, Socket connection){
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