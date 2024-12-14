# Preview
![Captura de Tela 2024-12-14 às 12 54 07](https://github.com/user-attachments/assets/9f503062-ecef-4704-bcf3-cc521383eb65)

![Captura de Tela 2024-12-14 às 17 32 25](https://github.com/user-attachments/assets/f73ce7fc-88c7-436a-96c1-d23c73cbbb16)


# How to execute the GUI

1. Open PowerShell as Administrator
2. Make possible the script execution:
```bash
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
3. Execute the script:
```bash
.\windows_dcv_setup.ps1
```
or execute with debug mode enabled:
```bash
.\windows_dcv_setup.ps1 -Debug
```

Using debug mode, all steps executed by the script will be checked, so you can troubleshoot a possible issue with your Windows Registry.

# FAQ

## My antivirus/antimalware said this script is a malware

It is false-positive! As this file need to change Windows registries, some antivirus/antimalwares can wrongly think this is a bad script. You can check the code. And if you still have some concern, you can see the file code in github and just copy the commands that you need to execute.
