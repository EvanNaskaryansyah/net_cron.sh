@echo off
REM ======================================================
REM Script untuk menyalin file .xls dari D:\dispenda
REM ke \\Elektra\dispenda tanpa menyalin subfolder
REM ======================================================

REM Sumber dan tujuan
set SOURCE=D:\dispenda
set TARGET=\\Elektra\dispenda

REM Membuat folder tujuan jika belum ada
if not exist "%TARGET%" (
    echo Membuat folder tujuan: %TARGET%
    mkdir "%TARGET%"
)

REM Menyalin hanya file .xls dari folder sumber (tanpa subfolder)
echo Menyalin file .xls dari %SOURCE% ke %TARGET% ...
xcopy "%SOURCE%\*.xls" "%TARGET%\" /Y /I

echo.
echo Selesai menyalin file .xls.
pause

