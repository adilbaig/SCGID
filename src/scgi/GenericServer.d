module scgi.GenericServer;

private :
    import std.stdio;
    
public import std.socket;
    
public :
    
    void GenericServer(string host, ushort port, void delegate(const byte[] request, Socket connection) handler)
    {
        auto listener = new TcpSocket();
        scope(exit)listener.close();
        assert(listener.isAlive);
        listener.blocking = false;
        listener.bind(new InternetAddress(host, port));
        listener.listen(10);
        writefln("Listening on %s:%d.", host, port);
        
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
                        auto bytes = getRequest(conn);
                        handler(bytes, conn);
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

    byte[] getRequest(Socket connection)
    {
        byte[1024 * 4] buff;
        byte[] rez;
        ulong len;
        
        do{
            len = connection.receive(buff);
            if (Socket.ERROR == len)
                throw new Exception("Connection error.");
            
            rez ~= buff[0 .. len];
        }while(len > buff.length);
        
        if (0 == rez.length)
            throw new Exception("Connection closed.");
            
        return rez;
    }