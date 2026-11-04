@echo off
echo ===================================================
echo   HireFlow - Khoi dong Microsoft SQL Server LocalDB
echo ===================================================

echo [1/2] Dang kiem tra va khoi dong LocalDB (mssqllocaldb)...
sqllocaldb start mssqllocaldb
if %ERRORLEVEL% NEQ 0 (
    echo LocalDB chua duoc tao, dang tao instance moi...
    sqllocaldb create mssqllocaldb
    sqllocaldb start mssqllocaldb
)

echo.
echo [2/2] Trang thai LocalDB:
sqllocaldb info mssqllocaldb

echo.
echo ===================================================
echo   Database LocalDB da san sang cho HireFlow!
echo ===================================================
pause

