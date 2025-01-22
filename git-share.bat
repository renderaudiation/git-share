@echo off
setlocal enabledelayedexpansion
set SIZE_THRESHOLD=104857600

where rar >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WinRAR is not found in PATH. Checking common installation locations...
    set "RAR_PATHS=C:\Program Files\WinRAR\Rar.exe;C:\Program Files (x86)\WinRAR\Rar.exe"
    for %%p in (%RAR_PATHS:;= %) do (
        if exist "%%p" (
            set "RAR=%%p"
            goto :found_rar
        )
    )
    echo WinRAR not found. Please install WinRAR or add it to your PATH.
    pause
    exit /b 1
)
set "RAR=rar"
:found_rar

where git >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Git is not found in PATH. Please install Git or add it to your PATH.
    pause
    exit /b 1
)

if not exist ".gitignore" type nul > .gitignore

for /r %%F in (*) do (
    set "file=%%F"
    set "size=%%~zF"
    set "ext=%%~xF"
    
    echo "!file!" | findstr /i /c:"\.git\\" >nul
    if errorlevel 1 (
        echo "!file!" | findstr /i /c:".part" >nul
        if errorlevel 1 (
            if !size! gtr %SIZE_THRESHOLD% (
                set "fullpath=%%F"
                set "repopath=!fullpath:%CD%=!"
                if "!repopath:~0,1!"=="\" set "repopath=!repopath:~1!"
                
                set "repopath=!repopath:\=/!"
                
                set "found="
                for /f "usebackq delims=" %%i in (".gitignore") do (
                    if "%%i"=="!repopath!" set "found=1"
                )
                
                if not defined found (
                    echo Found large file: "%%F"
                    echo !repopath!>>.gitignore
                    
                    if /i "!ext!" NEQ ".bak" (
                        echo Splitting: "%%F"
                        "%RAR%" a -v50m "%%~dpnF.rar" "%%F"
                        echo File processed: "%%F"
                    ) else (
                        echo Skipping split for .bak file: "%%F"
                    )
                    echo.
                ) else (
                    echo Skipping already processed file: "%%F"
                )
            )
        )
    )
)

echo All large files have been processed and added to .gitignore
echo.
echo Preparing to commit changes...

git status --porcelain >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
        set "DATESTAMP=%%c-%%a-%%b"
    )
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do (
        set "TIMESTAMP=%%a:%%b"
    )
    
    set "COMMIT_MSG=%DATESTAMP% - %TIMESTAMP%"
    
    echo.
    echo Adding changes to git...
    git add .
    
    echo.
    echo Committing changes...
    git commit -m "!COMMIT_MSG!"
    
    echo.
    echo Pushing changes to remote repository...
    git push
    
    if !ERRORLEVEL! EQU 0 (
        echo.
        echo Successfully committed and pushed changes to repository
    ) else (
        echo.
        echo Error pushing changes. Please check your remote repository configuration.
    )
) else (
    echo.
    echo No changes to commit
)
echo.
echo Script completed
pause