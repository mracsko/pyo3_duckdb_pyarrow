FROM mcr.microsoft.com/windows/servercore:ltsc2022

#Install Python 3.12.8
ADD https://www.python.org/ftp/python/3.12.8/python-3.12.8-amd64.exe /python-3.12.8.exe
RUN powershell.exe -Command \
    $ErrorActionPreference = 'Stop'; \
	Start-Process c:\python-3.12.8.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait ; \
	Remove-Item -Force python-3.12.8.exe;

SHELL ["cmd", "/S", "/C"]

#Latest VS Build Tools
ADD https://aka.ms/vs/17/release/vs_BuildTools.exe /vs_buildtools.exe
RUN vs_buildtools.exe --quiet --wait --norestart --nocache \
    --installPath C:\BuildTools \
    --add Microsoft.Component.MSBuild \
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362 \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64	\
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

ENTRYPOINT ["C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

# Latest Rust wit Rustup
ADD https://win.rustup.rs/x86_64 /rustup-init.exe
RUN start /w rustup-init.exe -y -v && echo "Error level is %ERRORLEVEL%"
RUN del rustup-init.exe

RUN setx /M PATH "C:\Users\ContainerAdministrator\.cargo\bin;%PATH%"

WORKDIR /app

COPY . .

RUN python -m venv .venv
RUN .venv\Scripts\activate.bat && pip install maturin==1.8.1
RUN .venv\Scripts\activate.bat && pip install pyarrow==18.1.0
RUN .venv\Scripts\activate.bat && maturin develop
RUN .venv\Scripts\activate.bat && python test-works.py
RUN .venv\Scripts\activate.bat && python test-fails.py