# all settings for this image are set via /etc/profile.d/hepsim.sh


Minimize the image

# list installed by size
rpm -qa --queryformat '%10{size} - %-25{name} \t %{version}\n' | sort -n


find /home/hepsim/  -name ".git*" -exec rm -R {} \;
find /home/hepsim/fpadsim-1.4/ -type f -name '*.o' -exec rm {} +
