function Split-Array
{
<#
    .SYNOPSIS
        Split array into multiple arrays

    .PARAMETER Parts
        Split array into this number of sub-arrays dividing elements equally

    .PARAMETER Size
        Split array into sub-arrays with maximum size of this argument.

    .OUTPUTS
        Array of arrays
#>
    param
    (
        [Array]$Array,

        [Parameter(ParameterSetName = 'Parts')]
        [int]$Parts,

        [Parameter(ParameterSetName = 'Size')]
        [int]$Size
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'Parts'
        {
            $partSize = [Math]::Ceiling($Array.count / $parts)
        }

        'Size'
        {
            $partSize = $size
            $Parts = [Math]::Ceiling($Array.count / $size)
        }
    }

    $outArray = @()

    for ($i=1; $i -le $Parts; $i++)
    {
        $start = (($i - 1) * $partSize)
        $end = ($i * $partSize) - 1

        if ($end -ge $Array.count - 1)
        {
            $end = $Array.count - 1
        }

        $outArray += ,@($Array[$start..$end])
    }

    return ,$outArray
}

