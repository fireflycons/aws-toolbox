<#
    .SYNOPSIS
        Guess encoding of text file

    .PARAMETER Path
        Path to file to examine

    .OUTPUTS
        [Encoding] object of detected encoding

    .LINK
        https://unicodebook.readthedocs.io/guess_encoding.html
#>
function Get-FileEncoding
{
    param
    (
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf))
    {
        throw "File not found: $Path"
    }

    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -Path $Path).Path)

    try
    {
        # 1. Check BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        {
            return New-Object System.Text.UTF8Encoding($true)
        }

        if ($bytes.Length -ge 4)
        {
            if ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF)
            {
                # UTF32-LE
                return New-Object System.Text.UTF32Encoding($false, $true)
            }

            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00)
            {
                # UTF32-BE
                return New-Object System.Text.UTF32Encoding($true, $true)
            }
        }

        if ($bytes.Length -ge 2)
        {
            if ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF)
            {
                # UTF-16 LE
                return New-Object System.Text.UTF32Encoding($false, $true)
            }

            if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE)
            {
                # UTF-16 BE
                return New-Object System.Text.UTF32Encoding($true, $true)
            }
        }

        # Read rest of file and guess encoding
        $isUnicode = $false

        for ($i = 0; $i -lt $bytes.Length; ++$i)
        {
            $byte = $bytes[$i]

            if ($byte -lt 32 -and (9, 10, 13) -inotcontains $byte)
            {
                # CTRL char and not whitespace
                $isUnicode = $true
            }

            if ($byte -lt 0x7F)
            {
                # 1 byte sequence: U+0000..U+007F
                continue
            }

            $isUnicode = $true

            if (0xC2 -le $byte -and $byte -le 0xDF)
            {
                # 0b110xxxxx: 2 bytes sequence
                $codeLength = 2
            }
            elseif (0xE0 -le $byte -and $byte -le 0xEF)
            {
                # 0b1110xxxx: 3 bytes sequence
                $codeLength = 3
            }
            elseif (0xF0 -le $byte -and $byte -le 0xF4)
            {
                # 0b11110xxx: 4 bytes sequence
                $codeLength = 4
            }
            else
            {
                # Unicode - going to assume LE as windows and moxt linux run on x86 architecture
                return New-Object System.Text.UTF32Encoding($false, $false)
            }

            if ($i + $codeLength - 1 -ge $bytes.Length)
            {
                # truncated string or invalid byte sequence
                throw "Invalid text file format - cannot determine encoding"
            }

            # Check continuation bytes: bit 7 should be set, bit 6 should be
            # unset (b10xxxxxx).
            for ($j = 1; $j -lt $codeLength; ++$j)
            {
                if ($bytes[$i + $j] -band 0xC0 -ne 0x80)
                {
                    # Unicode - going to assume LE as windows and moxt linux run on x86 architecture
                    return New-Object System.Text.UTF32Encoding($false, $false)
                }
            }

            if ($codeLength -eq 2)
            {
                # 2 bytes sequence: U+0080..U+07FF
                $b0 = [int]$bytes[$i]
                $b1 = [int]$bytes[$i + 1]
                $ch = (($b0 -band 0x1f) -shl 6) + ($b1 -band 0x3f)

                if ($ch -ge 0x0800)
                {
                    # Unicode - going to assume LE as windows and moxt linux run on x86 architecture
                    return New-Object System.Text.UTF32Encoding($false, $false)
                }
            }
            elseif ($codeLength -eq 3)
            {
                # 3 bytes sequence: U+0800..U+FFFF
                $b0 = [int]$bytes[$i]
                $b1 = [int]$bytes[$i + 1]
                $b2 = [int]$bytes[$i + 2]
                $ch = (($b0 -band 0x0f) -shl 12) + (($b1 -band 0x3f) -shl 6) + ($b2 -band 0x3f)

                if ($ch -lt 0x0800)
                {
                    # Unicode - going to assume LE as windows and moxt linux run on x86 architecture
                    return New-Object System.Text.UTF32Encoding($false, $false)
                }
            }
            elseif ($codeLength -eq 4)
            {
                # 4 bytes sequence: U+10000..U+10FFFF
                $b0 = [int]$bytes[$i]
                $b1 = [int]$bytes[$i + 1]
                $b2 = [int]$bytes[$i + 2]
                $b2 = [int]$bytes[$i + 3]
                $ch = (($b0 -band 0x07) -shl 18) + (($b1 -band 0x3f) -shl 12) + (($b2 -band 0x3f) -shl 6) + ($b3 -band 0x3f)

                if (($ch -lt 0x10000) -or (0x10FFFF -lt $ch))
                {
                    # Unicode - going to assume LE as windows and moxt linux run on x86 architecture
                    return New-Object System.Text.UTF32Encoding($false, $false)
                }
            }
        }

        # If we make it here, then UTF8 (unicode) no BOM or ASCII
        if ($isUnicode)
        {
            return New-Object System.Text.UTF8Encoding($false, $false)
        }

        return New-Object System.Text.ASCIIEncoding
    }
    finally
    {
        # Garbage collect
        $bytes = $null
    }
}