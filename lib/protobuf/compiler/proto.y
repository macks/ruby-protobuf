class Protobuf::ProtoParser
rule
  proto : proto_item
          { result = val }
        | proto proto_item
          { result << val[1] }

  proto_item : message
             | extend
             | enum
             | import
             | package
             | option
             | service
             | ';'
               { }

  import : 'import' string_literal ';'
           { result = [:import, val[1]] }

  package : 'package' IDENT dot_ident_list ';'
            { result = [:package, val[2].unshift(val[1])] }

  dot_ident_list :
                   { result = [] }
                 | dot_ident_list '.' IDENT
                   { result << val[2] }

  option : 'option' option_body ';'
           { result = [:option, val[1]] }

  option_body : IDENT dot_ident_list '=' constant
                { result = [val[1].unshift(val[0]), val[3]] }

  message : 'message' IDENT message_body
            { result = [:message, val[1], val[2]] }

  extend : 'extend' user_type '{' extend_body_list '}'
           { result = [:extend, val[1], val[3]] }

  extend_body_list : 
                     { result = [] }
                   | extend_body_list extend_body
                     { result << val[1] }

  extend_body : field
              | group
              | ';'
                { }

  enum : 'enum' IDENT '{' enum_body_list '}'
         { result = [:enum, val[1], val[3]] }

  enum_body_list :
                   { result = [] }
                 | enum_body_list enum_body
                   { result << val[1] }

  enum_body : option
            | enum_field
            | ';'
              { }

  enum_field : IDENT '=' integer_literal ';'
               { result = [val[0], val[2]] }

  service : 'service' IDENT '{' service_body_list '}'
            { result = [:service, val[1], val[3]] }

  service_body_list :
                      { result = [] }
                    | service_body_list service_body
                      { result << val[1] }

  service_body : option
               | rpc
               | ';'
                 { }

  rpc : 'rpc' IDENT '(' user_type ')' 'returns' '(' user_type ')' ';'
        { result = [:rpc, val[1], val[3], val[7]] }

  message_body : '{' message_body_body_list '}'
                 { result = val[1] }

  message_body_body_list :
                           { result = [] }
                         | message_body_body_list message_body_body
                           { result << val[1] }

  message_body_body : field
                    | enum
                    | message
                    | extend
                    | extensions
                    | group
                    | option
                    | ';'
                      { }

  group : label 'group' CAMEL_IDENT '=' integer_literal message_body
          { result = [:group, val[0], val[2], val[4], val[5]] }

  field : label type IDENT '=' integer_literal ';'
          { result = [:field, val[0], val[1], val[2], val[4]] }
        | label type IDENT '=' integer_literal '[' field_option_list ']' ';'
          { result = [:field, val[0], val[1], val[2], val[4], val[6]] }

  field_option_list : field_option
                      { result = val }
                    | field_option_list ',' field_option
                      { result << val[2] }

  field_option : option_body
               | 'default' '=' constant
                 { result = [:default, val[2]] }

  extensions : 'extensions' extension comma_extension_list ';'
               { result = [:extensions, val[2].unshift(val[1])] }

  comma_extension_list : 
                         { result = [] }
                       | ',' extension
                         { result << val[1] }

  extension : integer_literal
            | integer_literal 'to' integer_literal
              { result = [val[0], val[2]] }
            | integer_literal 'to' 'max'
              { result = [val[0], :max] }

  label : 'required'
        | 'optional'
        | 'repeated'

  type : 'double' | 'float' | 'int32' | 'int64' | 'uint32' | 'uint64'
       | 'sint32' | 'sint64' | 'fixed32' | 'fixed64' | 'sfixed32' | 'sfixed64'
       | 'bool' | 'string' | 'bytes' | user_type

  user_type : IDENT dot_ident_list
              { result = val[1].unshift(val[0]) }
            | '.' IDENT dot_ident_list
              { result = val[1].unshift(val[0]) }

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
        when /\A(required|optional|repeated|import|package|option|message|extend|enum|service|rpc|returns|group|default|extensions|to|max|double|float|int32|int64|uint32|uint64|sint32|sint64|fixed32|fixed64|sfixed32|sfixed64|bool|string|bytes)/
          @q.push [$&, $&]
        when /\A[1-9]\d*/, /\A0(?![.xX0-9])/
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
        when /\A[a-zA-Z_][\w_]*/
          @q.push [:IDENT, $&.to_sym]
        when /\A[A-Z][\w_]*/
          @q.push [:CAMEL_IDENT, $&.to_sym]
        when /\A./
          @q.push [$&, $&]
        else
          raise ArgumentError.new(line) 
        end
        line = $'
      end
    end
    do_parse
  end

  def next_token
    @q.shift
  end

---- footer

parser = Protobuf::ProtoParser.new
if ARGV[0]
  File.open ARGV[0], 'r' do |f|
    result = parser.parse(f)
    require 'pp'
    PP.pp result
  end
else
  parser.parse $stdin
end

