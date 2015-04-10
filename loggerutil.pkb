create or replace package body generator_pkg is
   --==============================--
   --== Private Global Variables ==--
   --==============================--
   g_package constant varchar2(31) := $$plsql_unit || '.';
   type g_columns_tt is table of user_tab_cols%rowtype;

   --======================--
   --== Private Programs ==--
   --======================--
   procedure pl (p_text in varchar2)
   is
   begin
      dbms_output.put_line(p_text);
   end pl;
   --==
   procedure log_parameter(p_arg_name in varchar2) is
      l_arg_name varchar2(150) := lower(p_arg_name);
   begin
     pl('      logger.append_param (p_params => l_params'||
        ', p_name => '''||l_arg_name||''''||
        ', p_val => '||l_arg_name||
        ');'
        );
   end log_parameter;
   --==

   function determine_proc_func (p_procedure in varchar2)
      return varchar2
   is
      l_retval varchar2(1);
      l_package   varchar2(30);
      l_procedure varchar2(30);
   begin
      l_package := upper (substr (p_procedure, 1, instr (p_procedure, '.')-1));
      l_procedure := upper (substr (p_procedure, instr (p_procedure, '.') + 1));
      select 'F'
        into l_retval
        from user_arguments
       where package_name = l_package
         and object_name = l_procedure
         and argument_name is null
         and in_out = 'OUT'; -- only functions have a NULL argument_name type OUT
      return l_retval;
   exception
      when no_data_found
      then
         l_retval := 'P';
         return l_retval;
      when too_many_rows
      then
         l_retval := 'F';
         return l_retval;
   end determine_proc_func;
   
   --==
   procedure log_parameters(p_procedure in varchar2) is
      overl  dbms_describe.number_table;
      posn  dbms_describe.number_table;
      levl  dbms_describe.number_table;
      arg   dbms_describe.varchar2_table;
      dtyp  dbms_describe.number_table;
      defv  dbms_describe.number_table;
      inout dbms_describe.number_table;
      len   dbms_describe.number_table;
      prec  dbms_describe.number_table;
      scal  dbms_describe.number_table;
      n     dbms_describe.number_table;
   begin
      dbms_describe.describe_procedure(object_name                => p_procedure
                                      ,reserved1                  => null
                                      ,reserved2                  => null
                                      ,overload                   => overl
                                      ,position                   => posn
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
                                      ,include_string_constraints => false);
      for i in 1 .. overl.count
      loop
         begin
            if overl(i) <> overl(i - 1)
            then
               -- Show if it concerns an Overloading
               -- Making it easier to pick the correct template
               pl('********************');
               pl('** Overloading: ' || to_char(overl(i)) ||
                                    ' **');
               pl('********************');
            end if;
         exception
            when no_data_found then
               null;
         end;
         if inout(i) <> 1
            and levl(i) = 0
         then
            -- Only for IN or IN/OUT arguments are
            -- added to the logger
            -- In case the level is greater than 0
            -- it is a RECORD of TABLE type
            -- For this type we will only show
            -- the number of entries
            log_parameter(p_arg_name => arg(i));
         end if;
      end loop;
   end log_parameters;
   --==
   
   procedure proc (p_procedure  in varchar2
                  ,p_standalone in boolean
                  )
   is
      l_procedure varchar2(255) := substr (p_procedure, instr (p_procedure, '.') + 1);
   begin
      pl ('   is');
      if p_standalone
      then
         pl ('      l_scope  constant varchar2(61) := '''||l_procedure||''';');
      else
         pl ('      l_scope  constant varchar2(61) := g_package||'''||l_procedure||''';');
      end if;
      pl ('      l_params logger.tab_param;');
      pl ('   begin');
      log_parameters (p_procedure => p_procedure);
      pl ('      logger.log_information (p_text    => ''Start''');
      pl ('                             ,p_scope   => l_scope');
      pl ('                             ,p_params  => l_params');
      pl ('                             );');
      pl ('      [==> Actual Program goes here ==]');
      pl ('      logger.log_information (p_text    => ''End''');
      pl ('                             ,p_scope   => l_scope');
      pl ('                             );');
      pl ('   end '||l_procedure||';');
   end proc;
   --==
   
   procedure func (p_procedure in varchar2
                  ,p_standalone in boolean
                  )
   is
      l_procedure varchar2(255) := substr (p_procedure, instr (p_procedure, '.') + 1);
   begin
      pl ('   is');
      if p_standalone
      then
         pl ('      l_scope  constant varchar2(61) := '''||l_procedure||''';');
      else
         pl ('      l_scope  constant varchar2(61) := g_package||'''||l_procedure||''';');
      end if;
      pl ('      l_params logger.tab_param;');
      pl ('      l_retval ;');
      pl ('   begin');
      log_parameters (p_procedure => p_procedure);
      pl ('      logger.log_information(p_text    => ''Start''');
      pl ('                            ,p_scope   => l_scope');
      pl ('                            ,p_params  => l_params');
      pl ('                            );');
      pl ('      [==> Actual Program goes here ==]');
      pl ('      logger.log_information(p_text  => ''Return Value: ''|| l_retval ');
      pl ('                            ,p_scope => l_scope');
      pl ('                            );');
      pl ('      logger.log_information(p_text  => ''End''');
      pl ('                            ,p_scope => l_scope');
      pl ('                            );');
      pl ('      return l_retval;');
      pl ('   end '||l_procedure||';');
   end func;

   --=====================--
   --== Public Programs ==--
   --=====================--
   --==
   procedure template (p_procedure  in varchar2
                      ,p_standalone in boolean := false)
   is
      l_proc_type varchar2(1);
   begin
      l_proc_type := determine_proc_func (p_procedure => p_procedure);
      case l_proc_type 
         when 'P'
         then
            proc (p_procedure  => p_procedure
                 ,p_standalone => p_standalone
                 );
         when 'F'
         then
            func (p_procedure  => p_procedure
                 ,p_standalone => p_standalone
                 );
      end case;
   end template;
   
--============================--
--== Initialization Section ==--
--============================--
begin
   null;
end generator_pkg;
/
