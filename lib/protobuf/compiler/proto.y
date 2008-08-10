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

  package : 'package' IDENT dot_ident_list ';'

  dot_ident_list :
                 | dot_ident_list '.' IDENT

  option : 'option' option_body ';'

  option_body : IDENT dot_ident_list '=' constant

  message : 'message' IDENT message_body

  extend : 'extend' user_type '{' extend_body_list '}'

  extend_body_list : 
                   | extend_body_list extend_body

  extend_body : field
              | group
	      | ';'

  enum : 'enum' IDENT '{' enum_body_list '}'

  enum_body_list :
                 | enum_body_list enum_body

  enum_body : option
            | enum_field
	    | ';'

  enum_field : IDENT '=' integer_literal ';'

  service : 'service' IDENT '{' service_body_list '}'

  service_body_list :
                    | service_body_list service_body

  service_body : option
               | rpc
	       | ';'

  rpc : 'rpc' IDENT '(' user_type ')' 'returns' '(' user_type ')' ';'

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

  group : label 'group' CAMEL_IDENT '=' integer_literal message_body

  field : label type IDENT '=' integer_literal ';'
        | label type IDENT '=' integer_literal '[' field_option_list ']' ';'

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

  user_type : IDENT dot_ident_list
            : '.' IDENT dot_ident_list

  constant : IDENT
           | integer_literal
	   | FLOAT_LITERAL
	   | STRING_LITERAL
	   | BOOLEAN_LITERAL
  
  integer_literal : DEC_INTEGER
                  | HEX_INTEGER
                  | OCT_INTEGER
end

---- inner

  def parse(f)
    @q = []
    f.each do |line|
      until line.empty? do
        case line
        when /\A\s+/, /\A\/\/.*/
          ;
        when /\A[a-zA-Z_][\w_]*/
          @q.push [:IDENT, $&.to_sym]
        when /\A[A-Z][\w_]*/
          @q.push [:CAMEL_IDENT, $&.to_sym]
        when /\A[1-9]\d*/
          @q.push [:DEC_INTEGER, $&.to_i]
        when /\A0[xX]([A-Fa-f0-9])+/
          @q.push [:HEX_INTEGER, $&.to_i(0)]
        when /\A0[0-7]+/
          @q.push [:OCT_INTEGER, $&.to_i(0)]
        when /\A\d+(\.\d+)?([Ee][\+-]?\d+)?/
          @q.push [:FLOAT_LITERAL, $&.to_f]
        when /\A(true|false)/
          @q.push [:BOOLEAN_LITERAL, $& == 'true']
        when /\A"(?:[^"\\]+|\\.)*"/, /\A'(?:[^'\\]+|\\.)*'/
          @q.push [:STRING_LITERAL, eval($&)]
        when /\A(import|package|option|message|extend|enum|service|rpc|returns|group|default|extensions|to|max|required|optional|repeated|double|float|int32|int64|uint32|uint64|sint32|sint64|fixed32|fixed64|sfixed32|sfixed64|bool|string|bytes)/
          @q.push [$&, $&]
        when /\A./
          @q.push [$&, $&]
        else
          raise ArgumentError.new(line) 
        end
        line = $'
      end
    end
  end

---- footer

parser = Protobuf::ProtoParser.new
if ARGV[0]
  File.open ARGV[0], 'r' do |f|
    parser.parse f
  end
else
  parser.parse $stdin
end

