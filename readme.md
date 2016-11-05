STEPS for running server

1. Install 'ruby'
2. ruby socket_server.rb in terminal


TESTING

/api/request

curl "http://localhost:8080/api/request?connId=23&timeout=30"


/api/serverStatus

curl http://localhost:8080/api/serverStatus


/api/kill

 curl -X PUT -d {"connId":"23"} "http://localhost:8080/api/kill"
{"status":"ok"}




