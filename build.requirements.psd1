@{
    # Some defaults for all dependencies
    PSDependOptions         = @{
        Target     = 'CurrentUser'
        Parameters = @{
            AllowClobber       = $True
            SkipPublisherCheck = $True
        }
    }

    'psake'                 = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.7.4'
        Tags           = @('Desktop', 'Core')
    }
    'PSDeploy'              = @{
        DependencyType = 'PSGalleryModule'
        Version        = '1.0.1'
        Tags           = @('Desktop', 'Core')
    }
    'BuildHelpers'          = @{
        DependencyType = 'PSGalleryModule'
        Version        = '2.0.7'
        Tags           = @('Desktop', 'Core')
    }
    'Pester'                = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.7.3'
        Tags           = @('Desktop', 'Core')
    }
    'platyps'               = @{
        DependencyType = 'PSGalleryModule'
        Version        = '0.12.0'
        Tags           = 'Desktop'
    }
    'AWSPowerShell'         = @{
        DependencyType = 'PSGalleryModule'
        Version        = '3.3.485.0'
        Tags           = 'Desktop'
    }
    'AWSPowerShell.netcore' = @{
        DependencyType = 'PSGalleryModule'
        Version        = '3.3.485.0'
        Tags           = 'Core'
    }
}