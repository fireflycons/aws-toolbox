@{
    # Some defaults for all dependencies
    PSDependOptions                     = @{
        Target     = 'CurrentUser'
        Parameters = @{
            AllowClobber       = $True
            SkipPublisherCheck = $True
        }
    }

    'psake'                             = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.7.4'
        Tags           = @('Desktop', 'Core')
    }
    'PSDeploy'                          = @{
        DependencyType = 'PSGalleryModule'
        Version        = '1.0.1'
        Tags           = @('Desktop', 'Core')
    }
    'BuildHelpers'                      = @{
        DependencyType = 'PSGalleryModule'
        Version        = '2.0.7'
        Tags           = @('Desktop', 'Core')
    }
    'Pester'                            = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.7.3'
        Tags           = @('Desktop', 'Core')
    }
    'platyps'                           = @{
        DependencyType = 'PSGalleryModule'
        Version        = '0.12.0'
        Tags           = 'Desktop'
    }
    'AWS.Tools.Common'                  = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.AutoScaling'             = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.SecurityToken'           = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.CloudFormation'          = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.EC2'                     = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.S3'                      = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.CloudwatchLogs'          = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.Lambda'                  = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.SimpleSystemsManagement' = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.ElasticBeanstalk'        = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.ElasticLoadBalancing'    = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
    'AWS.Tools.ElasticLoadBalancingV2'  = @{
        DependencyType = 'PSGalleryModule'
        Version        = '4.0.4.0'
        Tags           = @('Desktop', 'Core')
    }
}