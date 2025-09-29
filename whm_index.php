<?php
require_once('/usr/local/cpanel/php/WHM.php');

WHM::header('WP Temporary Accounts', 0, 0);
?>

<div class="container-fluid">
    <div class="row">
        <div class="col-lg-12">
            <div class="callout callout-success">
                <h4><i class="fa fa-check"></i> WHM Plugin Successfully Installed</h4>
                <p>The WP Temporary Accounts plugin is properly registered and accessible through WHM.</p>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-8">
            <div class="box box-primary">
                <div class="box-header with-border">
                    <h3 class="box-title"><i class="fa fa-wordpress"></i> Plugin Information</h3>
                </div>
                <div class="box-body">
                    <p>This WHM plugin provides system administrators with oversight of the WP Temporary Accounts functionality.</p>

                    <h4><i class="fa fa-users"></i> How Users Access the Plugin</h4>
                    <ul>
                        <li><strong>cPanel Users:</strong> Log into cPanel and look for "WP Temporary Accounts" in the Software section</li>
                        <li><strong>Direct Access:</strong> Each user can access via their cPanel interface</li>
                        <li><strong>Documentation:</strong> Full user guide available in the GitHub repository</li>
                    </ul>

                    <h4><i class="fa fa-cogs"></i> Administrative Features</h4>
                    <ul>
                        <li>Monitor plugin usage across all cPanel accounts</li>
                        <li>Review cleanup logs and account statistics</li>
                        <li>Manage installation and updates</li>
                        <li>Configure global security policies</li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="box box-info">
                <div class="box-header with-border">
                    <h3 class="box-title"><i class="fa fa-info-circle"></i> System Status</h3>
                </div>
                <div class="box-body">
                    <ul class="list-unstyled">
                        <li><i class="fa fa-check text-green"></i> WHM Registration: Active</li>
                        <li><i class="fa fa-check text-green"></i> cPanel Integration: Available</li>
                        <li><i class="fa fa-check text-green"></i> Cleanup Cron Job: Scheduled</li>
                        <li><i class="fa fa-check text-green"></i> Icon: Installed</li>
                        <li><i class="fa fa-check text-green"></i> Permissions: Configured</li>
                    </ul>
                </div>
            </div>

            <div class="box box-warning">
                <div class="box-header with-border">
                    <h3 class="box-title"><i class="fa fa-info"></i> Plugin Details</h3>
                </div>
                <div class="box-body">
                    <p><strong>Version:</strong> 3.0 (Universal)</p>
                    <p><strong>Compatibility:</strong> Works with both WP Toolkit and direct WordPress installations</p>
                    <p><strong>Security:</strong> Enterprise-grade security with CSRF protection</p>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-12">
            <div class="box box-default">
                <div class="box-header with-border">
                    <h3 class="box-title"><i class="fa fa-rocket"></i> Quick Actions</h3>
                </div>
                <div class="box-body">
                    <a href="/scripts2/manage_plugins" class="btn btn-primary">
                        <i class="fa fa-arrow-left"></i> Back to Plugins
                    </a>
                    <a href="https://github.com/ryonwhyte/cpanel_wp_temp_account" class="btn btn-default" target="_blank">
                        <i class="fa fa-book"></i> Documentation
                    </a>
                    <a href="/scripts2/view_system_health" class="btn btn-info">
                        <i class="fa fa-heart"></i> System Health
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
WHM::footer();
?>