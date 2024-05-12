# Define the package names to be uninstalled
$packageNames = @(
    "Clipchamp",
    "Cortana",
    "Microsoft News",
    "MSN Weather",
    "Xbox",
    "Office",
    "Microsoft People",
    "Microsoft Sticky Notes",
    "Windows Maps",
    "Xbox TCUI",
    "Xbox Game Bar Plugin",
    "Xbox Game Bar",
    "Xbox Identity Provider",
    "Xbox Game Speech Window",
    "Your Phone",
    "Mail and Calendar",
    "Microsoft Teams",
    "Power Automate",
    "Microsoft To Do",
    "Movies & TV",
    "Microsoft OneDrive",
    "Microsoft Solitaire Collection"
)

foreach ($packageName in $packageNames) {
    # Uninstall the package without confirmation
    #winget uninstall --id $packageName
    winget uninstall $packageName --accept-source-agreements --disable-interactivity
}
