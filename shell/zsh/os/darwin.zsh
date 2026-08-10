# macOS. Sourced by conf.d/05-environment.zsh.
#
# Everything that only makes sense on this OS goes here -- environment, PATH
# and aliases alike. Homebrew is deliberately NOT here: Linuxbrew exists, so
# it is handled platform-independently in 05-environment.zsh.

[[ -d /opt/homebrew/share/android-ndk ]] && export ANDROID_NDK_HOME=/opt/homebrew/share/android-ndk

[[ -d /usr/local/sbin ]] && path+=(/usr/local/sbin)
