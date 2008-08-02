class Protobuf::Parser
rule
  stmt_list : stmt
            | stmt_list stmt

  stmt : package_stmt
       | import_stmt
       | option_stmt
       | message_def
       | extend_def
       | enum_def
       | service_def

  package_stmt : PACKAGE fqcn_package ';'

  fqcn_package : ident
               | fqcn_package '.' ident

  import_stmt : IMPORT STRING ';'

  option_stmt : OPTION ident '=' STRING ';'
              | OPTION ident '=' ident ';'

  message_def : MESSAGE ident '{' message_item_list '}'

  message_item_list : message_item
                    | message_item_list message_item 

  message_item : RULE type ident '=' INTEGER ';'
               | RULE type ident '=' INTEGER '[' DEFAULT '=' ident ']' ';'
               | RULE type ident '=' INTEGER '[' DEFAULT '=' number ']' ';'
	       | option_stmt
	       | extend_stmt
	       | message_def
	       | extend_def
	       | enum_def

  type : TYPE | IDENT

  number : INTEGER | FLOAT

  extend_stmt | EXTENSIONS INTEGER TO INTEGER ';'

  extend_def : EXTEND ident '{' message_item_list '}'

  enum_def : ENUM ident '{' enum_item_list '}'

  enum_item_list : enum_item
                 | enum_item_list enum_item

  enum_item : ident '=' INTEGER ';'

  service_def : SERVICE ident '{' RPC ident '(' ident ')' RETURNS '(' ident ')' '}' ';'

  ident : PACKAGE | IDENT | MESSAGE | RULE | TYPE | EXTENSIONS | EXTEND | ENUM | SERVICE | RPC | RETURNS | TO | DEFAULT

---- inner

  def initialize
    @indent = 0
  end

  RESERVED = {
    'package' => :PACKAGE,
    'message' => :MESSAGE,
    'extensions' => :EXTENSIONS,
    'extend' => :EXTEND,
    'enum' => :ENUM,
    'service' => :SERVICE,
    'rpc' => :RPC, 
    'returns' => :RETURNS,
    'to' => :TO,
    'default' => :DEFAULT,
    'required' => :RULE,
    'optional' => :RULE,
    'repeated' => :RULE,
    'double' => :TYPE,
    'float' => :TYPE,
    'int32' => :TYPE,
    'int64' => :TYPE,
    'uint32' => :TYPE,
    'uint64' => :TYPE,
    'sint32' => :TYPE,
    'sint64' => :TYPE,
    'fixed32' => :TYPE,
    'fixed64' => :TYPE,
    'sfixed32' => :TYPE,
    'sfixed64' => :TYPE,
    'bool' => :TYPE,
    'string' => :TYPE,
    'bytes' => :TYPE,
  }

  def parse(f)
    @q = []
    lineno = 1
    f.each do |line|
      line.strip!
      until line.empty? do
        case line
	when /\A\s+/, /\A\/\/.*/
	  ;
	when /\A[a-zA-Z_]\w*/
          word = $&
	  @q.push [RESERVED[word] || :IDENT, [lineno, word.to_sym]]
        when /\A\d+\.\d+/
	  @q.push [:FLOAT, [lineno, $&.to_f]]
        when /\A\d+/
	  @q.push [:INTEGER, [lineno, $&.to_i]]
	when /\A"(?:[^"\\]+|\\.)*"/, /\A'(?:[^'\\]+|\\.)*'/
	  @q.push [:STRING, [lineno, eval($&)]]
	when /\A./
	  @q.push [$&, [lineno, $&]]
	else
	  raise RuntimeError, 'must not happen'
	end
	line = $'
      end
      lineno += 1
    end
    @q.push [false, '$']

    do_parse
  end

  def next_token
    @q.shift
  end

  def on_error(t, v, values)
    raise Racc::ParseError, "syntax error on #{v[1].inspect} at line.#{v[0]}"
  end

---- footer

File.open(ARGV.shift, 'r') do |f|
  Protobuf::Parser.new.parse f
end
