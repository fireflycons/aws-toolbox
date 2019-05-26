function Get-OperatingSystem
{
    if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)
    {
        return "Windows"
    }

    if ($IsLinux)
    {
        return "Linux"
    }

    if ($IsMacOs)
    {
        return "MacOS"
    }

    throw "Cannot determine operating system!"
}