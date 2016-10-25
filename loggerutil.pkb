create or replace package body loggerutil is
   --==============================--
   --== Private Global Variables ==--
   --==============================--
   g_package constant varchar2(31) := $$plsql_unit || '.';

   g_client_info varchar2 (30) := sys_context ('userenv', 'client_info');

   type argument_signature is record
      (position number --Position 0 returns the values for the return type of a function.
      ,lvl      number --If the argument is a composite type, such as record, then this parameter returns the level of the datatype
      ,argname  varchar2(30)-- Name of the argument
      -- 0: IN
      -- 1: OUT
      -- 2: IN OUT
      ,inout    number
      ,dty      number
      );
   type argument_signatures is table of argument_signature
      index by pls_integer;
   type stored_procs is table of argument_signatures
      index by pls_integer; -- overlading number

   g_proc_template varchar2(32767) :=
   '   is
      l_scope  constant varchar2(61) := g_package||''#procname#'';
      l_params logger.tab_param;
      /*
      #docarguments# TODO
      */
   begin
      #logarguments#
      logger.log_information (p_text    => ''Start''
                             ,p_scope   => l_scope
                             ,p_params  => l_params
                             );
      [==> TODO: Actual Program goes here ==]
      logger.log_information (p_text    => ''End''
                             ,p_scope   => l_scope
                             );
   end #procname#;';

   g_func_template varchar2(32767) :=
   '   is
      l_scope  constant varchar2(61) := g_package||''#procname#'';
      l_params logger.tab_param;
      l_retval TODO;
      /*
      #docarguments# TODO
      */
   begin
      #logarguments#
      logger.log_information(p_text    => ''Start''
                            ,p_scope   => l_scope
                            ,p_params  => l_params
                            );
      [==> TODO: Actual Program goes here ==]
      logger.log_information(p_text  => ''Return Value: ''|| l_retval
                            ,p_scope => l_scope
                            );
      logger.log_information(p_text  => ''End''
                            ,p_scope => l_scope
                            );
      return l_retval;
   end #procname#;';

   g_pref_type               logger_prefs.pref_type%type := 'LOGGERUTIL';
   g_pref_function_template  logger_prefs.pref_name%type := 'FUNCTION_TEMPLATE';
   g_pref_procedure_template logger_prefs.pref_name%type := 'PROCEDURE_TEMPLATE';


   --======================--
   --== Private Programs ==--
   --======================--
   procedure pl (p_text in varchar2)
   is
   begin
      if p_text is not null
      then
         dbms_output.put_line(p_text);
      end if;
   end pl;

   --==
   procedure pl (p_text1 in varchar2, p_text2 in varchar2)
   is
   begin
      pl (p_text1||': '||p_text2);
   end pl;

   --==
   procedure show (p_args in argument_signatures)
   is
      l_idx pls_integer;
   begin
      l_idx := p_args.first;
      while l_idx is not null
      loop
            pl('position: '||p_args(l_idx).position||', '||
               'level: '||p_args(l_idx).lvl      ||', '||
               'argumentname: '||p_args(l_idx).argname||', '||
               'inout: '||p_args(l_idx).inout||', '||
               'dty: '||p_args(l_idx).dty
               );
         l_idx := p_args.next (l_idx);
      end loop;
   end show;

   --==
   procedure show (p in stored_procs)
   is
      l_idx pls_integer;
   begin
      l_idx := p.first;
      while l_idx is not null
      loop
         pl ('*** overloading: '||l_idx);
         show (p_args => p(l_idx));
         l_idx := p.next (l_idx);
      end loop;
   end show;

   --==
   function pf (p_proc_type in varchar2)
      return varchar2
   is
   begin
      return case p_proc_type
             when 'P' then 'Procedure'
             when 'F' then 'Function'
             end;
   end pf;

   --==
   function get_template (p_proc_type in varchar2)
      return varchar2
   is
      l_retval varchar2 (32767);
   begin
      l_retval := logger.get_pref (p_pref_type => g_pref_type
                                  ,p_pref_name => case p_proc_type
                                                  when 'P'
                                                  then g_pref_procedure_template
                                                  when 'F'
                                                  then g_pref_function_template
                                                  end);

      if l_retval is null
      then
         l_retval := case p_proc_type
                     when 'P'
                     then g_proc_template
                     when 'F'
                     then g_func_template
                     end;
      end if;
      return l_retval;
   end get_template;

   --==
   function parse_template (p_template in varchar2)
      return dbms_utility.lname_array
   is
      l_cnt    pls_integer;
      l_line   varchar2(4000);
      l_retval dbms_utility.lname_array;
   begin
       -- Move the Template text to an Array of Stings
      l_cnt := regexp_count (rtrim (p_template, chr(10))||chr(10), chr(10));
      for i in 1.. l_cnt
      loop
         l_line := regexp_substr (p_template, '[^'||chr(10)||']+', 1, i);
         l_retval (l_retval.count + 1) := l_line;
       end loop;
      return l_retval;
   end parse_template;

   --==
   function determine_proc_func (p_procedure in argument_signatures)
      return varchar2
   is
      l_retval varchar2(1);
   begin
      begin
         if p_procedure(0).position = 0
         then
            l_retval := 'F';
         end if;
      exception
         when no_data_found
         then
            l_retval := 'P';
      end;
      return l_retval;
   end determine_proc_func;

   --==
   procedure format_logparameter (p_replace_line in varchar2
                                 ,p_arg_name     in varchar2
                                 )
   is
      l_arg_name varchar2(150) := lower(p_arg_name);
      new_line   varchar2(4000);
   begin
      new_line := replace (p_replace_line
                          ,'#logarguments#'
                          ,'logger.append_param (p_params => l_params'||
                           ', p_name => '''||l_arg_name||''''||
                           ', p_val => '||l_arg_name||');'
                          );
     pl(new_line);
   end format_logparameter;

   --==
   procedure format_docparameter (p_replace_line in varchar2
                                 ,p_arg_name     in varchar2
                                 ,p_arg_type     in number
                                 )
   is
      l_arg_name varchar2(150) := lower(p_arg_name);
      new_line   varchar2(4000);
   begin
      new_line := replace (p_replace_line
                          ,'#docarguments#'
                          ,l_arg_name||
                           case
                              when p_arg_type = 0 then ' in '
                              -- when p_arg_type = 1 and p_arg_name is null then ' returns'
                              when p_arg_type = 1 then ' out '
                              when p_arg_type = 2 then ' in/out '
                           end
                          );
     pl(new_line);
   end format_docparameter;

   --==
   procedure log_parameters (p_replace_line in varchar2
                            ,p_arguments    in argument_signatures
                            )
   is
      l_idx pls_integer;
   begin
      l_idx := p_arguments.first;
      while l_idx is not null
      loop
         if p_arguments(l_idx).inout <> 1
            and p_arguments(l_idx).position <> 0
         then
            -- Only for IN or IN/OUT arguments are
            -- added to the logger
            format_logparameter (p_replace_line => p_replace_line
                                ,p_arg_name     => p_arguments(l_idx).argname
                                );
         end if;
         l_idx := p_arguments.next (l_idx);
      end loop;
   end log_parameters;

   --==
   procedure doc_parameters (p_replace_line in varchar2
                            ,p_arguments    in argument_signatures
                            )
   is
      l_idx pls_integer;
   begin
      l_idx := p_arguments.first;
      while l_idx is not null
      loop
-- show (p_arguments);
         -- all arguments are show in #docarguments#
         -- except the return clause from a function
         if p_arguments(l_idx).position <> 0
         then
            format_docparameter (p_replace_line => p_replace_line
                                ,p_arg_name => p_arguments(l_idx).argname
                                ,p_arg_type => p_arguments(l_idx).inout
                                );
         end if;
         l_idx := p_arguments.next (l_idx);
      end loop;
   end doc_parameters;

   --==
   procedure process (p_procedure in varchar2
                     ,p_signature in argument_signatures
                     ,p_proc_type in varchar2
                     )
   is
      l_template_tt dbms_utility.lname_array;
      l_arguments   argument_signatures;
      l_line        varchar2 (4000);
      l_idx         pls_integer;
      l_proc_name   varchar2(255) := substr (p_procedure, instr (p_procedure, '.') + 1);
   begin
      -- Retrieve the Template and create a collection
      -- of individual lines of it
      l_template_tt := parse_template (p_template => get_template (p_proc_type => p_proc_type));
      -- Determine all the argument for the given procedure
      l_arguments := p_signature;
      -- Process the Template Array
      -- Don't replace the #placeholders# in the Template Array
      -- but replace them in the actual output
      l_idx := l_template_tt.first;
      while l_idx is not null
      loop
         l_line := l_template_tt(l_idx);
         if instr (l_template_tt (l_idx), '#procname#') > 0
         then
            l_line := replace (l_template_tt (l_idx), '#procname#', l_proc_name);
         end if;
         if instr (l_template_tt (l_idx), '#docarguments#')> 0
         then
            doc_parameters (p_replace_line => l_line
                           ,p_arguments    => l_arguments
                           );
            l_line := null; -- replace has been taken care of in called procedure
         end if;
         if instr (l_template_tt (l_idx), '#logarguments#')> 0
         then
            log_parameters (p_replace_line => l_line
                           ,p_arguments    => l_arguments
                           );
            l_line := null; -- replace has been taken care of in called procedure
         end if;
         pl (l_line);
         l_idx := l_template_tt.next (l_idx);
      end loop;
   end process;

   --
   function describe (p_procedure in varchar2)
      return stored_procs
   is
      overl    dbms_describe.number_table;
      posn     dbms_describe.number_table;
      levl     dbms_describe.number_table;
      arg      dbms_describe.varchar2_table;
      dtyp     dbms_describe.number_table;
      defv     dbms_describe.number_table;
      inout    dbms_describe.number_table;
      len      dbms_describe.number_table;
      prec     dbms_describe.number_table;
      scal     dbms_describe.number_table;
      n        dbms_describe.number_table;
      --
      l_retval stored_procs;
l_idx pls_integer;
   begin
      dbms_describe.describe_procedure (object_name                => p_procedure
                                       ,reserved1                  => null
                                       ,reserved2                  => null
                                       ,overload                   => overl
                                       --Position 0 returns the values for the return type of a function.
                                       ,position                   => posn
                                       --If the argument is a composite type, such as record, then this parameter returns the level of the datatype
                                       ,level                      => levl
                                       ,argument_name              => arg
                                       ,datatype                   => dtyp
                                       ,default_value              => defv
                                       ,in_out                     => inout
                                       ,length                     => len
                                       ,precision                  => prec
                                       ,scale                      => scal
                                       ,radix                      => n
                                       ,spare                      => n
                                       ,include_string_constraints => false
                                       );
-- pl('**** Positions ****');
-- l_idx := posn.first;
-- while l_idx is not null
-- loop
--    pl(l_idx);
--    l_idx := posn.next (l_idx);
-- end loop;
-- pl('**** Levels ****');
--    l_idx := levl.first;
--    while l_idx is not null
--    loop
--       pl(l_idx);
--       l_idx := levl.next (l_idx);
--    end loop;
  -- pl ('*** overl: '||to_char (overl.count));
  -- pl ('*** posn : '||to_char (posn .count));
  -- pl ('*** levl : '||to_char (levl .count));
  -- pl ('*** arg  : '||to_char (arg  .count));
  -- pl ('*** dtyp : '||to_char (dtyp .count));
  -- pl ('*** defv : '||to_char (defv .count));
  -- pl ('*** inout: '||to_char (inout.count));
  -- pl ('*** len  : '||to_char (len  .count));
  -- pl ('*** prec : '||to_char (prec .count));
  -- pl ('*** scal : '||to_char (scal .count));
  -- pl ('*** n    : '||to_char (n    .count));

      for i in 1.. overl.count
      loop
         l_retval(overl(i))(posn(i)).position := posn(i);
         l_retval(overl(i))(posn(i)).lvl := levl(i);
         l_retval(overl(i))(posn(i)).argname := arg(i);
         l_retval(overl(i))(posn(i)).inout := inout(i);
         l_retval(overl(i))(posn(i)).dty := dtyp(i);
      end loop;
      return l_retval;
   end describe;

   --=====================--
   --== Public Programs ==--
   --=====================--
   --==
   procedure template (p_procedure  in varchar2)
   is
      l_proc_type varchar2(1);
      l_procs     stored_procs;
      l_overl_idx pls_integer;
   begin
      l_procs := describe (p_procedure => p_procedure);
      l_overl_idx := l_procs.first;
      while l_overl_idx is not null
      loop
         -- per overloading determine determine_proc_func
         l_proc_type := determine_proc_func (l_procs(l_overl_idx));
         if l_overl_idx > 0
         then
            pl ('##################');
            pl ('### Overloading', to_char (l_overl_idx));
            pl ('### Type       ', pf (l_proc_type));
            pl ('##################');
         end if;
         -- per overloading generate the correct template
         process (p_procedure => p_procedure
                 ,p_signature => l_procs (l_overl_idx)
                 ,p_proc_type => l_proc_type
                 );
         l_overl_idx := l_procs.next(l_overl_idx);
      end loop;
   end template;

   --==
   procedure reset_default_templates
   is
      pragma autonomous_transaction;
   begin
      logger.del_pref (p_pref_type => g_pref_type
                      ,p_pref_name => g_pref_function_template
                      );
      logger.del_pref (p_pref_type => g_pref_type
                      ,p_pref_name => g_pref_procedure_template
                      );
      commit;
   end reset_default_templates;

   --==
   procedure set_custom_template (p_type     in varchar2 -- P or F
                                 ,p_template in varchar2
                                 )
   is
      pragma autonomous_transaction;
   begin
      if p_template is not null
      then
         case upper (p_type)
         when 'P'
         then
            logger.set_pref (p_pref_type  => g_pref_type
                            ,p_pref_name  => g_pref_procedure_template
                            ,p_pref_value => p_template
                            );
         when 'F'
         then
            logger.set_pref (p_pref_type  => g_pref_type
                            ,p_pref_name  => g_pref_function_template
                            ,p_pref_value => p_template
                            );
         end case;
      else
         rollback;
         raise_application_error (-20000, 'Custom Template cannot be NULL');
      end if;
      commit;
   exception
      when case_not_found
      then
         rollback;
         raise_application_error (-20000, 'Type must be "P" or "F"');
   end set_custom_template;

   --==
   procedure set_client_info (p_client_info in varchar2)
   is
   begin
      g_client_info := sys_context('userenv','client_info');
      dbms_application_info.set_client_info (p_client_info);
   end set_client_info;

   --==
   procedure reset_client_info
   is
   begin
      dbms_application_info.set_client_info (g_client_info);
   end reset_client_info;

--============================--
--== Initialization Section ==--
--============================--
begin
   null;
end loggerutil;
/
show error
