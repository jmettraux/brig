
require 'spec_helper'


describe Brig::Runner do
end

describe Brig do

  before(:all) do
    build_brig
  end
  after(:all) do
    nuke_brig
  end

  context 'without EM' do

    describe '.exec' do

      it 'returns the stdout and stderr for a give command' do

        stdout, stderr = nil

        Brig.exec('id', :chroot => 'spec_target') do |out, err|
          stdout = out
          stderr = err
        end

        stderr.should == ''

        if Brig.uname == 'Darwin'
          stdout.should match(/\(nobody\)/)
        else
          stdout.should match(/\(brig\)/)
        end
      end
    end

    describe '.run' do

      it 'receives ruby code and returns [ stdout, stderr ]' do

        stdout, stderr = nil

        Brig.run('p :hello', :chroot => 'spec_target') do |out, err|
          stdout = out
          stderr = err
        end

        stderr.should == ''
        stdout.chomp.should == ':hello'
      end
    end

    describe '.eval' do

      it 'receives ruby code and returns the result as a string' do

        out = nil

        Brig.eval(
          ':hello',
          :chroot => 'spec_target',
          :on_success => lambda { |result| out = result },
          :on_failure => lambda { |stderr, code| })

        out.should == 'hello'
      end

      it 'receives ruby code and returns the result as JSON' do

        out = nil

        Brig.eval(
          '[ 1, 2, 3 ]',
          :chroot => 'spec_target',
          :on_success => lambda { |result| out = result },
          :on_failure => lambda { |stderr, code| })

        out.should == [ 1, 2, 3 ]
      end

      it 'calls :on_failure in case of error' do

        stderr, code = nil

        Brig.eval(
          'do_fail',
          :chroot => 'spec_target',
          :on_success => lambda { |result| },
          :on_failure => lambda { |err, cod| stderr = err; code = cod })

        code.should == 'do_fail'
        stderr.should match(/undefined local variable/)
      end
    end
  end

  context 'with EM' do

    describe '.exec' do

      it 'returns the stdout and stderr for a give command' do

        stdout, stderr = nil

        EM.run {

          Brig.exec('id', :chroot => 'spec_target') do |out, err|
            stdout, stderr = out, err
            EM.stop
          end
        }

        stderr.should == ''

        if Brig.uname == 'Darwin'
          stdout.should match(/\(nobody\)/)
        else
          stdout.should match(/\(brig\)/)
        end
      end
    end

    describe '.run' do

      it 'receives ruby code and returns [ stdout, stderr ]' do

        stdout, stderr = nil

        EM.run {

          Brig.run('p :hello', :chroot => 'spec_target') do |out, err|
            stdout, stderr = out, err
            EM.stop
          end
        }

        stderr.should == ''
        stdout.chomp.should == ':hello'
      end
    end

    describe '.eval' do

      it 'receives ruby code and returns the result as a string' do

        out = nil

        EM.run {

          Brig.eval(
            ':hello',
            :chroot => 'spec_target',
            :on_success => lambda { |result| out = result; EM.stop },
            :on_failure => lambda { |stderr, code| EM.stop })
        }

        out.should == 'hello'
      end

      it 'receives ruby code and returns the result as JSON' do

        out = nil

        EM.run {

          Brig.eval(
            '[ 1, 2, 3 ]',
            :chroot => 'spec_target',
            :on_success => lambda { |result| out = result; EM.stop },
            :on_failure => lambda { |stderr, code| EM.stop })
        }

        out.should == [ 1, 2, 3 ]
      end

      it 'calls :on_failure in case of error' do

        stderr, code = nil

        EM.run {

          Brig.eval(
            'do_fail',
            :chroot => 'spec_target',
            :on_success => lambda { |result| EM.stop },
            :on_failure => lambda { |err, cod| stderr, code = err, cod; EM.stop })
        }

        code.should == 'do_fail'
        stderr.should match(/undefined local variable/)
      end
    end
  end
end

