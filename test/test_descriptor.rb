require 'test/unit'
require 'test/addressbook'
require 'protobuf/descriptor'
require 'protobuf/descriptor_proto'

class DescriptorTest < Test::Unit::TestCase
  include Google::Protobuf
  def test_build
    tutorial_proto = FileDescriptorProto.new
    tutorial_proto.package = 'Desc::Tutorial'

    person_proto = DescriptorProto.new
    tutorial_proto.message_type << person_proto
    person_proto.name = 'Person'

    person_name_proto = FieldDescriptorProto.new
    person_proto.field << person_name_proto
    person_name_proto.label = FieldDescriptorProto::Label::LABEL_REQUIRED
    person_name_proto.type = FieldDescriptorProto::Type::TYPE_STRING
    person_name_proto.name = 'name'
    person_name_proto.number = 1

    person_id_proto = FieldDescriptorProto.new
    person_proto.field << person_id_proto
    person_id_proto.label = FieldDescriptorProto::Label::LABEL_REQUIRED
    person_id_proto.type = FieldDescriptorProto::Type::TYPE_INT32
    person_id_proto.name = 'id'
    person_id_proto.number = 2

    person_email_proto = FieldDescriptorProto.new
    person_proto.field << person_email_proto
    person_email_proto.label = FieldDescriptorProto::Label::LABEL_OPTIONAL
    person_email_proto.type = FieldDescriptorProto::Type::TYPE_STRING
    person_email_proto.name = 'email'
    person_email_proto.number = 3

    person_phone_type_proto = EnumDescriptorProto.new
    person_proto.enum_type << person_phone_type_proto
    person_phone_type_proto.name = 'PhoneType'

    person_phone_type_mobile_proto = EnumValueDescriptorProto.new
    person_phone_type_proto.value << person_phone_type_mobile_proto
    person_phone_type_mobile_proto.name = 'MOBILE'
    person_phone_type_mobile_proto.number = 0

    person_phone_type_home_proto = EnumValueDescriptorProto.new
    person_phone_type_proto.value << person_phone_type_home_proto
    person_phone_type_home_proto.name = 'HOME'
    person_phone_type_home_proto.number = 1

    person_phone_type_work_proto = EnumValueDescriptorProto.new
    person_phone_type_proto.value << person_phone_type_work_proto
    person_phone_type_work_proto.name = 'WORK'
    person_phone_type_work_proto.number = 2

    person_phone_number_proto = DescriptorProto.new
    person_proto.nested_type << person_phone_number_proto
    person_phone_number_proto.name = 'PhoneNumber'

    person_phone_number_number_proto = FieldDescriptorProto.new
    person_phone_number_proto.field << person_phone_number_number_proto
    person_phone_number_number_proto.label = FieldDescriptorProto::Label::LABEL_REQUIRED
    person_phone_number_number_proto.type = FieldDescriptorProto::Type::TYPE_STRING
    person_phone_number_number_proto.name = 'number'
    person_phone_number_number_proto.number = 1
    
    person_phone_number_type_proto = FieldDescriptorProto.new
    person_phone_number_proto.field << person_phone_number_type_proto
    person_phone_number_type_proto.label = FieldDescriptorProto::Label::LABEL_OPTIONAL
    person_phone_number_type_proto.type = FieldDescriptorProto::Type::TYPE_ENUM
    person_phone_number_type_proto.type_name = 'PhoneType'
    person_phone_number_type_proto.name = 'type'
    person_phone_number_type_proto.number = 2
    person_phone_number_type_proto.default_value = 'HOME'

    person_phone_phone_number_proto = FieldDescriptorProto.new
    person_proto.field << person_phone_phone_number_proto
    person_phone_phone_number_proto.label = FieldDescriptorProto::Label::LABEL_REPEATED
    person_phone_phone_number_proto.type = FieldDescriptorProto::Type::TYPE_MESSAGE
    person_phone_phone_number_proto.type_name = 'PhoneNumber'
    person_phone_phone_number_proto.name = 'phone'
    person_phone_phone_number_proto.number = 4

    address_book_proto = DescriptorProto.new
    tutorial_proto.message_type << address_book_proto
    address_book_proto.name = 'AddressBook'

    address_book_person_proto = FieldDescriptorProto.new
    address_book_proto.field << address_book_person_proto
    address_book_person_proto.label = FieldDescriptorProto::Label::LABEL_REPEATED
    address_book_person_proto.type = FieldDescriptorProto::Type::TYPE_MESSAGE
    address_book_person_proto.type_name = 'Person'
    address_book_person_proto.name = 'person'
    address_book_person_proto.number = 1

    proto = Protobuf::Descriptor::Descriptor.build tutorial_proto

    assert_nothing_raised do
      Desc::Tutorial::Person
    end
    assert_nothing_raised do
      Desc::Tutorial::Person.new
    end
    assert_equal ['email', 'id', 'name', 'phone'], 
      Desc::Tutorial::Person.fields.map{|tag, field| field.name}.sort

    assert_nothing_raised do
      Desc::Tutorial::Person::PhoneNumber
    end
    assert_nothing_raised do
      Desc::Tutorial::Person::PhoneNumber.new
    end
    assert_equal ['number', 'type'], 
      Desc::Tutorial::Person::PhoneNumber.fields.map{|tag, field| field.name}.sort

    assert_nothing_raised do
      Desc::Tutorial::Person::PhoneType
    end
    assert_equal 0, Desc::Tutorial::Person::PhoneType::MOBILE
    assert_equal 1, Desc::Tutorial::Person::PhoneType::HOME
    assert_equal 2, Desc::Tutorial::Person::PhoneType::WORK

    assert_nothing_raised do
      Desc::Tutorial::AddressBook
    end
  end

  def test_unbuild
    proto = Protobuf::Descriptor::FileDescriptor.unbuild Tutorial::Person
  end
end
