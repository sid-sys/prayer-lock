#!/usr/bin/env ruby
# Adds the Screen Time pieces to the Xcode project:
#   - 3 app extensions (ActivityMonitor, ShieldConfiguration, ShieldAction)
#   - the shared Swift file (ScreenTimeShared) in the app and in every extension
#   - ScreenTimePlugin.swift and Runner.entitlements in the Runner app
# Run it from the `ios` folder:   ruby scripts/add_screen_time_targets.rb
# It is safe to run twice: it stops if the work is already done.

require 'xcodeproj'

TEAM = 'W3QA63P2YL'
BASE_ID = 'com.coreinteractive.prayerLock'
DEPLOYMENT = '15.0'

project = Xcodeproj::Project.open('Runner.xcodeproj')
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner target not found' unless runner

if project.targets.any? { |t| t.name == 'ActivityMonitor' }
  puts 'Screen Time targets already in the project. Nothing to do.'
  exit 0
end

# ---------- shared file ----------
shared_group = project.main_group.new_group('ScreenTimeShared', 'ScreenTimeShared')
shared_ref = shared_group.new_file('ScreenTimeShared.swift')

# ---------- Runner: plugin + entitlements ----------
runner_group = project.main_group['Runner'] || project.main_group.new_group('Runner', 'Runner')
plugin_ref = runner_group.new_file('ScreenTimePlugin.swift')
runner_group.new_file('Runner.entitlements')

runner.add_file_references([plugin_ref, shared_ref])
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  config.build_settings['DEVELOPMENT_TEAM'] = TEAM
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
end

# ---------- the three extensions ----------
extensions = [
  { name: 'ActivityMonitor',     source: 'DeviceActivityMonitorExtension.swift' },
  { name: 'ShieldConfiguration', source: 'ShieldConfigurationExtension.swift' },
  { name: 'ShieldAction',        source: 'ShieldActionExtension.swift' },
]

embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins

extensions.each do |ext|
  name = ext[:name]
  target = project.new_target(:app_extension, name, :ios, DEPLOYMENT, nil, :swift)

  group = project.main_group.new_group(name, name)
  source_ref = group.new_file(ext[:source])
  group.new_file('Info.plist')
  group.new_file("#{name}.entitlements")

  target.add_file_references([source_ref, shared_ref])

  # Use the same Flutter .xcconfig files as Runner, so the version numbers match.
  runner_configs = runner.build_configurations.to_h { |c| [c.name, c] }
  target.build_configurations.each do |config|
    base = runner_configs[config.name]&.base_configuration_reference
    config.base_configuration_reference = base if base

    s = config.build_settings
    s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{BASE_ID}.#{name}"
    s['PRODUCT_NAME'] = '$(TARGET_NAME)'
    s['INFOPLIST_FILE'] = "#{name}/Info.plist"
    s['GENERATE_INFOPLIST_FILE'] = 'NO'
    s['CODE_SIGN_ENTITLEMENTS'] = "#{name}/#{name}.entitlements"
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['DEVELOPMENT_TEAM'] = TEAM
    s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT
    s['TARGETED_DEVICE_FAMILY'] = '1,2'
    s['SWIFT_VERSION'] = '5.0'
    s['SKIP_INSTALL'] = 'YES'
    s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                    '@executable_path/../../Frameworks']
    s['CLANG_ENABLE_MODULES'] = 'YES'
  end

  runner.add_dependency(target)
  build_file = embed.add_file_reference(target.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# Flutter's "Thin Binary" step must come AFTER the embed step, or Xcode reports a cycle.
thin = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin
  phases = runner.build_phases
  from = phases.to_a.index(embed)
  to = phases.to_a.index(thin)
  phases.move_from(from, to) if from && to && from > to
end

project.save
puts 'Added: ActivityMonitor, ShieldConfiguration, ShieldAction + ScreenTimeShared + Runner entitlements.'
