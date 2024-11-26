# Preview
![screen](https://github.com/user-attachments/assets/05aa2512-2746-4495-8b60-0628e24846fd)

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
