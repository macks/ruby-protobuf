class Protobuf::Parser
rule
  stmt_list : stmt
            | stmt_list stmt

  stmt : message_def
       | extend_def
       | service_def
       | package_def
       | import_stmt
       | option_stmt

  import_stmt : IMPORT 
