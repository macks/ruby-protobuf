require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'

require 'addressbook_org'

module TutorialExt
  class Person < ::Protobuf::Message
    optional :int32, :age, 100, :extension => true
  end
end
