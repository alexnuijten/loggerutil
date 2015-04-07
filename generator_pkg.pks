create or replace package generator_pkg is
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
   --==   The package where the procedure is going to
   --==   be placed will need to have a global constant:
   --==   * g_package constant varchar2(31) := $$plsql_unit || '.';
   --==   If it concerns a standalone procedure (not in a package)
   --==   then pass in TRUE for p_standalone
   --==
   --==   Template depends on DBMS_OTUPUT, therefore
   --==   Serveroutput needs to be turned on
   --==   * set serveroutput on
   --==
   --== Usage
   --==   exec generator_pkg.template ('package.procedure')
   --==   or
   --==   exec generator_pkg.template ('package.function')
   --==
   --== 2015-02-26: Alex Nuijten  Initial Creation
   
   procedure template (p_procedure   in varchar2
                      ,p_standalone  in boolean := false
                      );

end generator_pkg;
/
