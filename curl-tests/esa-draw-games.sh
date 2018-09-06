# mobile
curl -X GET \
  https://sit-draw-mobile.calottery.com/api/v2/draw-games/draws \
  -H 'cache-control: no-cache' \
  -H 'postman-token: 74ff950c-2310-b9e5-7291-722fd57f0665'

# 
curl -X GET \
  https://ca-cat-b2b.lotteryservices.com/api/v2/draw-games/draws \
  -H 'cache-control: no-cache' \
  -H 'postman-token: fe9d2374-4f95-c9ed-1620-116a0251d370' \
  -H 'x-channel-id: 0' \
  -H 'x-ex-system-id: 0' \
  -H 'x-site-id: 35'  
  
# Ticket inquiry  
curl -X POST \
  https://cat-draw-mobile.calottery.com/api/v2/draw-games/tickets/inquire \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'postman-token: cfc9d7a9-9734-1be0-cd4b-ff75b8be7164' \
  -H 'x-originator-id: 10002,0,0,0' \
  -H 'x-request-id: 0' \
  -H 'x-session-id: 10002,1000210,4' \
  -H 'x-site-id: 35' \
  -d '{ "ticketSerialNumber": "ZPNVZWKX7JWJL" }'  