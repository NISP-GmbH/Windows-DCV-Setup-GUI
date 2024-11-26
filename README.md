# Preview
![Captura de Tela 2024-11-21 às 00 15 31](https://github.com/user-attachments/assets/ea88fe10-a79d-4f60-b060-e110eaaf94e0)

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

Using debug mode, all steps execute by the script will be checked, so you can troubleshoot a possible issue with your Windows Registry.
