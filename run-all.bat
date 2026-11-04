@echo off
echo ========================================================
echo   HireFlow - Khoi chay Toan Bo Backend ^& Database
echo ========================================================

echo [1/3] Kiem tra va khoi dong Database LocalDB...
sqllocaldb start mssqllocaldb

echo [2/3] Chay Backend Web API (http://0.0.0.0:5136)...
echo Database Migrations va Seeding se tu dong duoc ap dung!
cd backend\HireFlow.Api
dotnet run --urls "http://0.0.0.0:5136"

