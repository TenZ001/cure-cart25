@echo off
echo Starting Cure Cart Servers...
echo.
echo This will start both the backend server (port 5000) and web server (port 4000)
echo The mobile app will work with real data when both servers are running
echo.
echo Press Ctrl+C to stop the servers
echo.

echo Starting Backend Server (port 5000)...
start "Backend Server" cmd /k "cd backend && npm start"

echo Starting Web Server (port 4000)...
start "Web Server" cmd /k "cd cure-cart-web && npm run server"

echo.
echo Both servers are starting...
echo Backend: http://localhost:5000
echo Web: http://localhost:4000
echo.
echo Wait for both servers to start before testing the mobile app
echo.

pause
