require "socket"
requests={}
server = TCPServer.new('localhost', 8080)

def request socket, requests, connId, timeout #handling response of /api/request
  Thread.current['startTime'] = Time.now #storing required information for each request in thread variable
  Thread.current['timeout']=timeout
  Thread.current['socket']=socket
  sleep(timeout)
  response= "{\"status\":\"ok\"}\r\n"
  socket.print response
  socket.close
  requests.delete(connId)
end

def server_status requests, socket #handling response of /api/serverStatus api
  response={}
  requests.each do |key, value|
    response[key]=value['timeout']-(Time.now-value['startTime']).to_i
  end
  socket.print response
  socket.print " 200 OK\r\n"
  socket.close
end

def kill_request requests, connId #killing a particular request given its connId
  socket=requests[connId]['socket']
  socket.print "{\"status\":\"killed\"}\r\n"
  socket.close
  Thread.kill requests[connId]
  requests.delete(connId)
end

def page_not_found socket # response when route doesn't match any defined route
  socket.print "HTTP/1.1 404 Not Found\r\n"
  socket.print "\r\n"
  socket.close
end

def parse_request request #parsing http verbe and route from url
  request_verb = request.split(' ')[0]
  route = request.split(' ')[1].split('?')[0]
  return request_verb, route
end

def parse_request_params request #parsing parameters from request parameters
  paramrequestsay = request.split('?')[1].split(' ')[0].split('&')
  connId=paramrequestsay[0].split('=')[1]
  timeout=paramrequestsay[1].split('=')[1].to_i
  return connId, timeout
end

def parse_request_body socket #parsing body of PUT/POST request
  headers = {}
  while line = socket.gets.split(' ', 2) #reading headers
    break if line[0] == ""
    headers[line[0].chop] = line[1].strip
  end
  body = socket.read(headers["Content-Length"].to_i) # reading data on basis of content length
  return body
end

loop do
  socket = server.accept
  request = socket.gets
  request_verb, route = parse_request request
  if request_verb=='GET' && route == '/api/request'
    connId, timeout=parse_request_params request
    unless requests.has_key? connId
      requests[connId] = Thread.new {
        request socket, requests, connId, timeout
      }
    else
      socket.print "Request with current connId in progress. Try a new id\r\n"
      socket.close
    end
  elsif request_verb=='GET' && route=='/api/serverStatus'
    server_status requests, socket
  elsif request_verb=='PUT' && route=='/api/kill'
    body=parse_request_body socket
    connId=body.split(':')[1].delete('}')
    if requests.has_key? connId
      kill_request requests, connId
      socket.print "{\"status\":\"ok\"}\r\n"
      socket.close
    else
      socket.print "{\"status\":\"invalid connetion Id:#{connId}\"}\r\n"
      socket.close
    end
  else
    page_not_found socket
  end
end
