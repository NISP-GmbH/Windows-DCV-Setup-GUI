# Preview
![Captura de Tela 2024-12-11 às 00 17 16](https://github.com/user-attachments/assets/2ecc847a-0d67-48e2-84c0-48d32acb0d6e)

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
