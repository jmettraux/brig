
JAIL=target
CRO="-u jmettraux -g staff"

sudo chroot $CRO $JAIL id
sudo chroot $CRO $JAIL ls -al
sudo chroot $CRO $JAIL bash -c "env"
sudo chroot $CRO $JAIL bash -u 'brig'
sudo chroot $CRO $JAIL /ruby/bin/ruby -v
sudo chroot $CRO $JAIL /ruby/bin/ruby -e "puts 'hello'"
sudo chroot $CRO $JAIL /ruby/bin/ruby -e "p $:"
sudo chroot $CRO $JAIL /ruby/bin/ruby -e "require 'pp'; pp :nada"
sudo chroot $CRO $JAIL /ruby/bin/ruby -e "require 'rubygems'; require 'rufus-json'; p Rufus::Json"
sudo chroot $CRO $JAIL /ruby/bin/ruby -e "require 'rubygems'; require 'yajl'; p Yajl; require 'rufus-json'; p Rufus::Json.decode('[1,2,3]');"

#sudo chroot $CRO $JAIL /ruby/bin/gem list --verbose
#sudo chroot $CRO $JAIL echo "..$GEM_PATH.."
#sudo chroot $CRO $JAIL /ruby/bin/gem install rufus-json --verbose 

