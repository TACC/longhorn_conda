Name:		conda
Version:	4.8.3
Release:	1
Summary:	RPM containing module files pointing to conda deployment on scratch
Group:		LSC
License:	BSD-3
URL:		https://github.com/TACC/longhorn_conda
Source:		%{name}-%{version}.tar.gz
BuildRoot:	%{?_tmppath}%{!?_tmppath:/var/tmp}/%{name}-%{version}-%{release}-root
Prefix:		/opt/apps

%define debug_package %{nil}

%description
RPM containing module files pointing to conda deployment on scratch

%prep
%setup -q
# Contains source
rm -rf %{buildroot}

%build
# Nothing to build

%install
ls
mkdir -p %{buildroot}/opt/apps
cp -r modulefiles %{buildroot}/opt/apps/
rm -rf conda.spec modulefiles

%files
%dir /opt/apps/modulefiles
%dir /opt/apps/modulefiles/*
/opt/apps/modulefiles/*/*lua

%clean
rm -rf %{buildroot}
