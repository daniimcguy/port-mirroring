 Automating Port Mirroring with PowerShell on the GigaCore 2nd Generation

As an alternative to using the API client manually, port mirroring can also be enabled using a PowerShell script. This method allows for quick and repeatable configuration of mirror sessions.

You’ll find attached a PowerShell script (port_mirroring_api.ps1) and an optional batch file (run_port_mirroring.bat) to launch it more easily.


The script is allowing you to specify:

    The session number (1–4)

    The destination port

    One or more source ports and their mirroring direction (ingress, egress, or bidirectional)

    Whether CPU traffic should be mirrored

The .bat file can be used to simplify execution. Make sure to edit the file to reflect the correct full path to the .ps1 script on your machine.

Alternatively, if you don't want to use the .bat, you can simply copy the script content directly into a PowerShell session on the target machine.

    ⚠ Note on corporate environments: Some corporate devices or IT-managed networks restrict PowerShell script execution entirely (due to Group Policies or restricted execution policies). If that's the case, this method unfortunately cannot be used unless temporary permissions are granted or execution policies are modified.
