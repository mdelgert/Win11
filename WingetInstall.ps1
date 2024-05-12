# Define the package names to be installed
$packageNames = @(
    "SomePythonThings.WingetUIStore",
    "Google.Chrome"
    "Notepad++.Notepad++",
    "Mozilla.Firefox.ESR",
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Logitech.OptionsPlus",
    "veeam.veeam-agent", #Veeam Agent for Microsoft Windows
    "Microsoft.PowerShell" #PowerShell 7-x64
)

foreach ($packageName in $packageNames) {
    # Install the package
    #winget install --id $packageName
    #winget install --exact --silent --scope machine --accept-source-agreements --accept-package-agreements $packageName
    winget install $packageName --silent --accept-source-agreements --accept-package-agreements 
}
