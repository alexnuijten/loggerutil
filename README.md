# loggerutil
- [What is LoggerUtil?](#what-is-loggerutil)
- [How do I use LoggerUtil?](#how-do-i-use-loggerutil)
- [Why am I not seeing any output?](#why-am-i-not-seeing-any-output)
- [Why is the signature missing?](#why-is-the-signature-of-the-procedurefunction-missing)
- [Why is the datatype for the return variable not generated?](#why-is-the-datatype-for-the-return-variable-not-generated)
- [Why are my empty lines removed from the template?](#why-are-my-empty-lines-removed-from-the-template)
- [Can I specify a Custom Template for my Procedure/Function?](#can-i-specify-a-custom-template-for-my-procedurefunction)
- [How do I reset the Template back to the default?](#how-do-i-reset-the-template-back-to-the-default)
- [Which placeholders can I use and What do they do?](#which-placeholders-can-i-use-and-what-do-they-do)
- [Does LoggerUtil support complex datatypes to generate the logging for?](#does-loggerutil-support-complex-datatypes-to-generate-the-logging-for)
- [Feedback/Issues](#feedbackissues)
- [License](#license)

# What is LoggerUtil?
The LoggerUtil project contains a PL/SQL package to supplement LOGGER (https://github.com/OraOpenSource/Logger)

loggerutil.template:
   generates a Procedure or Function body including instrumentation using the LOGGER
   package. This template will log all IN and IN/OUT arguments. See comments in
   package specification for more information.

# How do I use LoggerUtil?
Please refer to this blog for a simple example: http://nuijten.blogspot.nl/2015/04/speed-up-development-with-logger.html
# Why am I not seeing any output?
It depends on DBMS_OUTPUT, so you have to enable the output.
```sql
set serveroutput on format wrapped
```
# Why is the signature of the Procedure/Function missing?
In the datadictionary it is not possible to retrieve the signature of the stored procedure the way you entered it.
For instance when you use %TYPE (datatype anchored to the table columns), the datadictionary will just store the actual datatype (like NUMBER or VARCHAR2).
Because you just created the signature of the stored procedure anyway, simply copy it to the package body. Generate the template and paste this in the package body as well.

# Why is the datatype for the return variable not generated?
see -[Why is the signature of the Procedure/Function missing?](#why-is-the-signature-of-the-procedurefunction-missing)

# Why are my empty lines removed from the template?
Mainly because I don't like empty lines in source code, it just makes the text longer and I don't like scrolling.

# Can I specify a Custom Template for my Procedure/Function?
Use ``` set_custom_template ``` to enter your custom template for either a procedure (type is P) or function (type is F).
For example:
```sql
loggerutil.set_custom_template (p_type     => 'P'
                               ,p_template => 'your_custom_template'
                               );
```
In your custom template you can use  [placeholders](#which-placeholders-can-i-use-and-what-do-they-do).
Note: This depends on Issue #103 being implemented in Logger.


# How do I reset the Template back to the default?
The function ``` reset_default_templates ``` will remove the custom templates that are stored in the LOGGER_PREFS table.
```sql
loggerutil.reset_default_templates;
```
Alternatively you can use
```sql
logger.set_cust_pref ('CUST_FUNCTION_TEMPLATE', null);
logger.set_cust_pref ('CUST_PROCEDURE_TEMPLATE', null);
```
Note: This depends on Issue #103 being implemented in Logger.

# Which placeholders can I use and What do they do?
Placeholder    |Meaning
---------------|-------
#procname#     |The name of the procedure or function.
#docarguments# |All the arguments are listed (IN, OUT and IN/OUT). Handy for when you want to use this in the comments section. The text (or spaces) before the placeholder is placed before each argument.
#logarguments# |Only the IN and IN/OUT arguments are used for calls to Logger.

# Does LoggerUtil support complex datatypes to generate the logging for?
No, LoggerUtil doesn't generate Logger code for complex datatypes like Objects, Nested Tables, Varrays or Associative Arrays.

##Feedback/Issues
Please submit any feedback, suggestions, or issues on the project's [issue page](https://github.com/alexnuijten/loggerutil/issues).

#License

The MIT License (MIT)

Copyright (c) 2015 Alex Nuijten

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
