require 'test/unit'
#require 'protobuf/compiler/compiler_old'
require 'protobuf/compiler/compiler'

class CompilerTest < Test::Unit::TestCase
  def test_create_message
    assert_equal <<-eos.gsub(/^\s*\n/, '').strip, Protobuf::Compiler.new.create_message('test/addressbook.proto', '.', '.', false).gsub(/^\s*\n/, '').strip
require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'

module Tutorial
  
  class Person < ::Protobuf::Message
    required :string, :name, 1
    required :int32, :id, 2
    optional :string, :email, 3
    
    class PhoneType < ::Protobuf::Enum
      MOBILE = 0
      HOME = 1
      WORK = 2
    end
    
    class PhoneNumber < ::Protobuf::Message
      required :string, :number, 1
      optional :PhoneType, :type, 2, :default => :HOME
    end
    
    repeated :PhoneNumber, :phone, 4
    
    extensions 100..200
  end
  
  class Person < ::Protobuf::Message
    optional :int32, :age, 100, :extension => true
  end
  
  class AddressBook < ::Protobuf::Message
    repeated :Person, :person, 1
  end
end
    eos
  end

  def test_create_rpc
    file_contents = Protobuf::Compiler.new.create_rpc('test/rpc.proto', '.', '.', false)

    assert_source <<-eos, file_contents['./test/address_book_service.rb']
require 'protobuf/rpc/server'
require 'protobuf/rpc/handler'
require 'test/rpc'

class Tutorial::SearchHandler < Protobuf::Rpc::Handler
  request Tutorial::Person
  response Tutorial::AddressBook

  def self.process_request(request, response)
    # TODO: edit this method
  end
end

class Tutorial::AddHandler < Protobuf::Rpc::Handler
  request Tutorial::Person
  response Tutorial::Person

  def self.process_request(request, response)
    # TODO: edit this method
  end
end

class Tutorial::AddressBookService < Protobuf::Rpc::Server
  def setup_handlers
    @handlers = {
      :search => Tutorial::SearchHandler,
      :add => Tutorial::AddHandler,
    }
  end
end
    eos

    assert_source <<-eos, file_contents['./test/start_address_book_service']
#!/usr/bin/ruby
require 'address_book_service'

Tutorial::AddressBookService.new(:port => 9999).start
    eos

    assert_source <<-eos, file_contents['./test/client_search.rb']
#!/usr/bin/ruby
require 'protobuf/rpc/client'
require 'test/rpc'

# build request
request = Tutorial::Person.new
# TODO: setup a request
raise StandardError.new('setup a request')

# create blunk response
response = Tutorial::AddressBook.new

# execute rpc
Protobuf::Rpc::Client.new('localhost', 9999).call :search, request, response

# show response
puts response
    eos

    assert_source <<-eos, file_contents['./test/client_add.rb']
#!/usr/bin/ruby
require 'protobuf/rpc/client'
require 'test/rpc'

# build request
request = Tutorial::Person.new
# TODO: setup a request
raise StandardError.new('setup a request')

# create blunk response
response = Tutorial::Person.new

# execute rpc
Protobuf::Rpc::Client.new('localhost', 9999).call :add, request, response

# show response
puts response
    eos
  end

  def assert_source(ideal, real)
    assert_equal ideal.strip.gsub(/^\s*\n/, '').gsub(/\s+\n/, "\n"), real.strip.gsub(/^\s*\n/, '').gsub(/\s+\n/, "\n")
  end
end
