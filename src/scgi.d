module scgi;

private :
    import std.conv : to; 
    import std.string : indexOf, split;
    import std.stdio;
    import std.container : SList;
    
public import std.socket;
    
public :
    
    void SCGIServer(ushort port, void function(const Request, Socket) handler)
    {
        Socket listener = new TcpSocket();
        scope(exit) listener.close();
        assert(listener.isAlive);
        listener.blocking = false;
        listener.bind(new InternetAddress(port));
        listener.listen(10);
        writefln("Listening on port %d.", port);
        
        uint maxConnections = 60;
        SocketSet sset = new SocketSet(maxConnections + 1);
        Socket[] read;
        
        while(true)
        {
            sset.reset();
            sset.add(listener);
            foreach(s ; read)
                sset.add(s);
                
            Socket.select(sset, null, null);
            
            uint i = 0;
            while(i < read.length)
            {
                auto conn = read[i];
                if(sset.isSet(conn))
                {
                    try{
                        Request r = getRequest(conn);
                        handler(r, conn);
                    }catch(Exception e)
                    {
                        writeln(e);
                    }
                    finally
                    {
                        if (conn.isAlive)
                        {
                            conn.close();
                            writeln("Connection closed");
                        }
                        
                        read = std.algorithm.remove(read, i);
                        writefln("\tTotal connections: %d", read.length);
                    }
                }
                else
                    i++;
            }
                
            if(sset.isSet(listener))
            {
                Socket conn = listener.accept();
                conn.blocking = false;
                writef("Received connection from %s .. ", conn.remoteAddress().toString());
                read ~= conn;
            }
        }
    }

private :
    
    Request getRequest(Socket conn)
    {
        char[1024 * 2] buff;
        char[] receive;
        ulong bytes_read, header_length;
        long s;
        
        do {
            bytes_read += conn.receive(buff);
            receive ~= buff;
            
            //If the header length has not been calculated, do it.
            if(!header_length)
            {
                s = indexOf(receive,':');
                if (s == -1)
                    throw new Exception("Invalid SCGI request! - Length not given");
                   
                header_length = to!ulong(receive[0 .. s]);
            }
            
        }while(bytes_read > 0 
            && bytes_read < header_length);
        
        if (Socket.ERROR == bytes_read)
            throw new Exception("Connection error.");
        else if (0 == receive.length)
            throw new Exception("Connection closed.");
        
        auto headers = getHeaders(cast(immutable)receive[s + 1 .. s + header_length]);
        if ("CONTENT_LENGTH" !in headers)
            throw new Exception("Invalid SCGI request! - Header CONTENT_LENGTH not found");
        
        auto body_length = to!uint(headers["CONTENT_LENGTH"]);
        
        char[] body_data;
        if (body_length > 0)
            body_data = receive[s + header_length + 1 .. body_length];
        
        debug{ writeln("RECEIVED DATA : ", receive); }
        
        Request r = {headers, null, null, cast(immutable)body_data};
        if (headers["REQUEST_METHOD"] == "GET")
            r.get =  getParams(cast(immutable)headers["QUERY_STRING"]);
        if(headers["REQUEST_METHOD"] == "POST")
            r.post = getParams(cast(immutable)body_data[1 .. $]);
        
        return r;
    }

    string[string] getHeaders(string buffer)
    {
        string[] arr = split(buffer,"\0");
        
        string[string] ret;
        for(int i=0; i < arr.length; i += 2)
            ret[arr[i]] = arr[i + 1];
        
        return ret;
    }

    string[string] getParams(string queryString)
    {
        string[] arr = split(queryString,"&");
        
        string[string] ret;
        foreach(s; arr)
        {
            auto i = indexOf(s,'=');
            auto k = urldecode(s[0 .. i]);
            auto v = urldecode(s[i + 1 .. $]);
            ret[k] = v;
        }
        
        return ret;
    }

    string urldecode(string url)
    {
        int l;
    
        int hexvalue(char ch)
        {
            if (ch >= '0' && ch <= '9')
                return ch - '0';
            if (ch >= 'a' && ch <= 'f')
                return ch - 'a' + 10;
            if (ch >= 'A' && ch <= 'F')
                return ch - 'A' + 10;
            throw new Error("URL has an encoding value that is outside of the hexadecimal range.");
        }
    
        for (int c; c < url.length; c++, l++)
            if (url[c] == '%')
            {
                if (c + 3 > url.length)
                    throw new Error("URL has an encoding marker ('%') that is not followed by two characters.");
                c += 2;
            }
    
        if (l == url.length)
            return url;
    
        auto result = new char[l];
        l = 0;
    
        for (int c; c < url.length; c++, l++)
            if (url[c] == '%')
            {
                result[l] = to!char(hexvalue(url[c + 1]) * 16 + hexvalue(url[c + 2]));
                c += 2;
            }
            else
                result[l] = url[c];
    
        return cast(immutable)result;
    }

    struct Request{
        string[string] headers;
        string[string] get;
        string[string] post;
        string content;
    }

