create or replace package loggerutil is
   --==
   --== Generate a Template for a given
   --== procedure or function.
   --== The template will include references
   --== to LOGGER
   --==
   --== Prerequisites
   --==   The declaration of the Procedure or Function needs
   --==   to be available, i.e. it needs to be in the package
   --==   specification. It can't be a private.
   --==
   --==   When using the default templates:
   --==   The package where the procedure is going to
   --==   be placed will need to have a global constant:
   --==   * g_package constant varchar2(31) := $$plsql_unit || '.';
   --==
   --==   Template depends on DBMS_OTUPUT, therefore
   --==   Serveroutput needs to be turned on
   --==   In SQL*Plus:
   --==   * set serveroutput on format wrapped
   --==
   --== Usage
   --==   exec loggerutil.template ('package.procedure')
   --==   or
   --==   exec loggerutil.template ('package.function')
   --==
   --== 2015-02-26: Alex Nuijten  Initial Creation
   --== 2015-04-10: Alex Nuijten  Renamed pacakge to loggerutil
   --== 2015-04-15: Alex Nuijten  Parse custom layout for template
   --==                           removed p_standalone argument
   --== 2015-04-26: Alex Nuijten  Added procedures to set/reset
   --==                           Custom Templates.
   --==                           Dependencies:
   --==                           Issue #103 must be implemented in Logger
   --==                           (Logger Version 3.1.0)
   --== 2015-04-30: Alex Nuijten  Procedures to create/reset custom templates
   --== 2016-10-25: Alex Nuijten  Set and Reset Client Info Procedures

   procedure template (p_procedure in varchar2);


   --== Resets the Default Templates to the default setting
   procedure reset_default_templates;

   --== Create a custom template for (P)rocedure or (F)unction
   --== Currently the template cannot exceed 255 characters, this
   --== is caused by the limitation of the LOGGER_PREFS table
   procedure set_custom_template (p_type     in varchar2 -- P or F
                                 ,p_template in varchar2
                                 );

   --== When multiple developers use the same DB-schema
   --== to develop a common code base, logger data from one
   --== developer will quickly intermingle with other developer
   --== logger data making it difficult to determine the data of interest
   --== Using the set_client_info procedure allows you to set a specific
   --== name in the logger table, making it easier to keep track of your data
   procedure set_client_info (p_client_info in varchar2);
   --== The reset_client_info procedure will restore the client info
   --== to the original value
   procedure reset_client_info;

end loggerutil;
/
show error
