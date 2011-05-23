
JAIL=target

sudo chroot $JAIL id
sudo chroot $JAIL ls -al
sudo chroot $JAIL bash -c "env"
sudo chroot $JAIL bash -u 'brig'
sudo chroot $JAIL /ruby/bin/ruby -v
sudo chroot $JAIL /ruby/bin/ruby -e "puts 'hello'"
sudo chroot $JAIL /ruby/bin/ruby -e "p $:"
sudo chroot $JAIL /ruby/bin/ruby -e "require 'pp'; pp :nada"
sudo chroot $JAIL /ruby/bin/ruby -e "require 'rubygems'; require 'rufus-json'; p Rufus::Json"
sudo chroot $JAIL /ruby/bin/ruby -e "require 'rubygems'; require 'yajl'; p Yajl; require 'rufus-json'; p Rufus::Json.decode('[1,2,3]');"

#sudo chroot $JAIL /ruby/bin/gem list --verbose
#sudo chroot $JAIL echo "..$GEM_PATH.."
#sudo chroot $JAIL /ruby/bin/gem install rufus-json --verbose 

