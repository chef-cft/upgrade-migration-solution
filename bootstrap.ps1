param([String]$customer_id, [String]$datacollector_token)

Set-ExecutionPolicy Bypass -Scope Process -Force

if (!(Get-Command hab -ErrorAction SilentlyContinue)) {
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.ps1'))
}

Write-Output "By running this script, you accept the Chef license agreement"
hab license accept

$pkg_origin='migration'
$pkg_name='fingerprinter'

Write-Output "Install $pkg_origin/$pkg_name"

hab pkg install $pkg_origin/$pkg_name

Write-Output "Creating configuration overrides"
New-Item "C:\hab\user\fingerprinter\config" -ItemType Directory
Set-Content -Path "C:\hab\user\fingerprinter\config\user.toml" -Value @"
env_path_prefix = ";C:/WINDOWS;C:/WINDOWS/system32/;C:/WINDOWS/system32/WindowsPowerShell/v1.0;C:/ProgramData/chocolatey/bin;C:/Habitat/"

[chef_license]
acceptance = "accept"

[automate]
enable = true
server_url = "https://migration-$customer_id.success.chef.co/data-collector/v0/"
token = "$datacollector_token"
"@

Write-Output "Determining pkg_prefix for $pkg_origin/$pkg_name"

# Find latest semver and release ver folder
$pkg_prefix = Get-ChildItem "C:\hab\pkgs\$pkg_origin\$pkg_name"|
Select-Object fullname, @{n='version';e={[version]$_.name}}|
Sort-Object -Property version -Descending|
Select-Object -first 1|
ForEach-Object{Get-ChildItem $_.fullname}|
Select-Object fullname, @{n='Date';e={[int64]$_.name}}|
Sort-Object date -Descending|
Select-Object -first 1 -exp fullname

Write-Output "Found $pkg_prefix"

Write-Output "Running chef for $pkg_origin/$pkg_name"

cd $pkg_prefix
hab pkg exec $pkg_origin/$pkg_name chef-client.bat -z -c $pkg_prefix/config/bootstrap-config.rb
