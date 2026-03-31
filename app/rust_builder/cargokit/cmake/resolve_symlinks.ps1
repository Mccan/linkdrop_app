function Resolve-Symlinks {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path
    )

    [string] $separator = '/'
    [string[]] $parts = ($Path.Replace('\\', '/')).Split($separator)

    [string] $realPath = ''
    foreach ($part in $parts) {
        if ($realPath -and !$realPath.EndsWith($separator)) {
            $realPath += $separator
        }
        $realPath += $part
        # Some systems expose junction targets with unexpected characters.
        # Keep resolving where possible, but never fail the build for this helper.
        try {
            $item = Get-Item -LiteralPath $realPath -ErrorAction Stop
            if ($item.LinkTarget) {
                $realPath = $item.LinkTarget.Replace('\\', '/')
            }
        }
        catch {
            continue
        }
    }
    $realPath
}

$path=Resolve-Symlinks -Path $args[0]
Write-Host $path
