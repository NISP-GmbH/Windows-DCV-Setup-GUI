# Preview
![Captura de Tela 2024-12-05 às 14 18 35](https://github.com/user-attachments/assets/12b0980c-e202-4016-8a8e-535c2f0545a9)

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
