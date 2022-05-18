# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
# 

Name:       harbour-audiocut

# >> macros
%define __provides_exclude_from ^%{_datadir}/%{name}/lib/.*\\.so\\>
%define __requires_exclude_from ^%{_datadir}/%{name}/lib/.*\\.so\\>
# << macros

Summary:    Audioworks
Version:    1.3
Release:    1
Group:      Qt/Qt
License:    GPLv3
URL:        https://github.com/poetaster/harbour-audiocut
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   pyotherside-qml-plugin-python3-qt5
Requires:   ffmpeg
Requires:   ffmpeg-tools
BuildRequires:  qt5-qttools-linguist
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

%description
Audioworks is a small audio workbench. Trim/Splice, add echo! WIP.

%if "%{?vendor}" == "chum"
PackageName: Audioworks
Type: desktop-application
Categories:
 - Audio
DeveloperName: Mark Washeim (poetaster)
Custom:
 - Repo: https://github.com/poetaster/harbour-audiocut
Icon: https://github.com/poetaster/harbour-audiocut/raw/main/icons/172x172/harbour-audiocut.png
Screenshots:
 - https://raw.githubusercontent.com/poetaster/harbour-audiocut/main/screenshot-2.png
 - https://raw.githubusercontent.com/poetaster/harbour-audiocut/main/screenshot-3.png
 - https://raw.githubusercontent.com/poetaster/harbour-audiocut/main/screenshot-4.png
Url:
  Donation: https://www.paypal.me/poetasterFOSS
%endif

%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5 

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%attr(644,root,root) %{_datadir}/%{name}/qml/py/audiox.py
# >> files
# << files
