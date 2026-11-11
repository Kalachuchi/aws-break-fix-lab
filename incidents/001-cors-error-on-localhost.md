# 002: CORS error when testing frontend on localhost

## Symptom
The incident list was empty when opening the frontend at `http://localhost:8000`.
The live site on CloudFront worked fine.

The browser console showed:

`Access to fetch at 'https://hcyf1vav0g.execute-api.us-east-1.amazonaws.com/incidents' from origin 'http://localhost:8000' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.`

## Investigation
1. Opened the browser console (F12) and found the CORS error above.
   The network request itself returned HTTP 200, so the API was working.
   The browser was blocking the response, not the server.
2. Called the API from PowerShell. It returned data normally, which confirmed
   the backend was fine (CORS only applies in browsers).
3. Checked API Gateway (`bfl-incidents-http` → CORS). Allow-Origin only listed
   `https://d29uwddf0jdpjp.cloudfront.net`.
4. Remembered CORS had recently been tightened from `*` to the CloudFront
   domain only, which removed access for any other origin, including localhost.
5. Related: an earlier version of this issue happened when opening the page by
   double-clicking the file. That sends `Origin: null`, which API Gateway never
   allows. Fixed by serving the page with `python -m http.server 8000`.

## Root cause
API Gateway's CORS settings only allowed the CloudFront origin. Requests from
`http://localhost:8000` did not get an `Access-Control-Allow-Origin` header,
so the browser blocked the page from reading the response.

## Fix
Added `http://localhost:8000` as a second allowed origin in API Gateway
(`bfl-incidents-http` → CORS), keeping the CloudFront origin. Refreshed the
local page and the incident list loaded.

## Prevention
- When tightening CORS, list every origin that still needs access
  (production site and local dev).
- Use separate dev and prod settings so localhost is never needed in production.
- Remove `http://localhost:8000` from CORS once local development is done.
- Remember CORS is a browser rule, not API security. Use throttling,
  validation, and auth to protect the API.