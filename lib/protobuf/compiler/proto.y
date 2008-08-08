class Protobuf::ProtoParser
rule
  proto : proto_item
        | proto proto_item

  proto_item : message
             | extend
             | enum
             | import
             | package
             | option
             | ';'

  import : 'import' string_literal ';'

  package : 'package' ident dot_ident_list ';'

  dot_ident_list :
                 | dot_ident_list '.' ident

  option : 'option' option_body ';'

  option_body : ident dot_ident_list '=' constant

  extend : 'extend' user_type '{' extend_body_list '}'

  extend_body_list : 
                   | extend_body_list extend_body

  extend_body : field
              | group
	      | ';'

  enum : 'enum' ident '{' enum_body_list '}'

  enum_body_list :
                 | enum_body_list enum_body

  enum_body : option
            | enum_field
	    | ';'

  enum_field : ident '=' integer_literal ';'

  service : 'service' ident '{' service_body_list '}'

  service_body_list :
                    | service_body_list service_body

  service_body : option
               | rpc
	       | ';'

  rpc : 'rpc' ident '(' user_type ')' 'returns' '(' user_type ')' ';'

  message_body : '{' message_body_body_list '}'

  message_body_body_list :
                         | message_body_body_list messabe_body_body

  message_body_body : field
                    | enum
		    | message
		    | extend
		    | extensions
		    | group
		    | option
		    | ';'

  group : label 'group' camel_ident '=' integer_literal message_body

  field : label type ident '=' integer_literal ';'
        | label type ident '=' integer_literal '[' field_option_list ']' ';'

  field_option_list : field_option
                    | field_option ',' field_option

  field_option : option_body
               | 'default' '=' constant

  extensions : 'extensions' extension comma_extension_list ';'

  comma_extension_list : 
                       | ',' extension

  extension : integer_literal
            | integer_literal 'to' integer_literal
            | integer_literal 'to' 'max'

  label : 'required'
        | 'optional'
	| 'repeated'

  type : 'double' | 'float' | 'int32' | 'int64' | 'uint32' | 'uint64'
       | 'sint32' | 'sint64' | 'fixed32' | 'fixed64' | 'sfixed32' | 'sfixed64'
       | 'bool' | 'string' | 'bytes' | user_type

  user_type : ident dot_ident_list
            : '.' ident dot_ident_list

  constant : ident
           | integer_literal
	   | float_literal
	   | string_literal
	   | boolean_literal
  
