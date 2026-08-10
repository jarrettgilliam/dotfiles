# macOS. Sourced by shared/05-environment.sh.
#
# Everything that only makes sense on this OS goes here -- environment, PATH
# and aliases alike. Homebrew is deliberately NOT here: Linuxbrew exists, so
# it is handled platform-independently in 05-environment.sh.

[ -d /opt/homebrew/share/android-ndk ] && export ANDROID_NDK_HOME=/opt/homebrew/share/android-ndk

path_append /usr/local/sbin
