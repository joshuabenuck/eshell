# Menu: eshell
# Key: M3+Z

require 'java'
require 'prelude'

common_targets = [:clean, :dist, :reinstall]
register(:ant, {
  :dev => buildShell("dev/build.xml", [
    :clean, ["db-install", :db_install],
    ["db-install-unittests", :db_install_unittests],
    ["dist-and-deploy", :dist_and_deploy]
  ]),
  :core => buildShell("dev/src/core/build.xml", [
    :dist, ["redeploy-frontend", :redeploy_frontend, :rfe]
  ]),
  :console => buildShell("dev/src/console/build.xml", [:reinstall]),
  :rs => buildShell("dev/src/rs/build.xml", common_targets),
  :scheduler => common_targets,
  :remote => common_targets,
  :ldap => common_targets
})
register(:eshell, buildShell("build.xml", [:test, :dist]))
#project :mfs200; print ant.core.dist.redeploy_frontend.rfe
$bzUrl = "https://bugs.eclipse.org/bugs/"

run_shell()