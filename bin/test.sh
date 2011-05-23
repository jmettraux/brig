
sudo chroot target /ruby/bin/ruby -v
sudo chroot target /ruby/bin/ruby -e "puts 'hello'"
sudo chroot target /ruby/bin/ruby -e "p $:"
sudo chroot target /ruby/bin/ruby -e "require 'pp'; pp :nada"
sudo chroot target /ruby/bin/ruby -e "require 'rubygems'; require 'rufus-json'; p Rufus::Json"
sudo chroot target /ruby/bin/ruby -e "require 'rubygems'; require 'yajl'; p Yajl; require 'rufus-json'; p Rufus::Json.decode('[1,2,3]');"

#sudo chroot target /ruby/bin/gem list --verbose
#sudo chroot target echo "..$GEM_PATH.."
#sudo chroot target /ruby/bin/gem install rufus-json --verbose 

