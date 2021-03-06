/* HLang Parser Bison
 * created by Supragya Raj
 */

%{
#include <stdio.h>
#include "buildtime_hlang-lexer.h"
#include "hlang-lexer.h"
#include "hlang-parser.h"
#include "variable_mgmt.h"
#include "ast.h"
#include "verbose.h"

%}
%define api.value.type {char *}
%error-verbose

/* Terminals */
%token	MAPDECL	VARDECL	VARNAME	MELNAME	ARGVAR
%token	NSTRING	STRING	GSTRING	BROPEN	BRCLOSE	SHELLECHO
%token	FUNC	IF	ELIF	ELSE	WHILE	RETURN	BREAK	CONTINUE	FOR	IS
%token	EOS	PARANOPEN	PARANCLOSE	EXCLAMATION
%token	ASSIGN	FUNCCALL	COMMA
%token	GT	LT	EQ	NQ	GE	LAND	LOR
%token	LE	ERR	EOL
%token	ADD	INCR	SUB	DECR	MUL	EXP	DIV	TRUNCDIV

%%

script:
	%empty
	|script function
	/*|script alltokens    /* FOR DEBUGGING PROCESS    */
	;

function:
	FUNC enclosement				{if(PARSERVERBOSE())printf("\t<FUNCTION>\n"); ast_add_function($1);}
	;

enclosement:
	beginenc code BRCLOSE				{if(PARSERVERBOSE())printf("\t<ENCLOSEMENT>\n");}
	;

beginenc:
	BROPEN						{if(PARSERVERBOSE())printf("\t<ENCLOSEMENT BROPEN>\n"); struct ast_constructll *temp = malloc(sizeof(struct ast_constructll)); temp->next = currentconstructhead; currentconstructhead = temp;}
	;

code:
	%empty
	|code sequential_constuct			{if(PARSERVERBOSE())printf("\t<CODE: SEQUENTIAL CONSTRUCT>\n"); ast_add_seq();}
	|code selective_constructs			{if(PARSERVERBOSE())printf("\t<CODE: SELECTIVE CONSTRUCTS>\n"); }
	|code iterative_constructs			{if(PARSERVERBOSE())printf("\t<CODE: ITERATIVE CONSTRUCTIS>\n"); ast_add_iter("iter");	}
	;




/* Different constructs */

sequential_constuct:
	mapvariables_declaration EOS			{if(PARSERVERBOSE())printf("\t<SEQUENTIAL CONSTRUCT: MAP VARIABLE DECLARATIONS>\n"); ast_add_seq_mapdecl();}
	|generalvariables_declaration EOS		{if(PARSERVERBOSE())printf("\t<SEQUENTIAL CONSTRUCT: GEN VARIABLE DECLARATIONS>\n"); ast_add_seq_vardecl();}
	|SHELLECHO EOS					{if(PARSERVERBOSE())printf("\t<SEQUENTIAL CONSTRUCT: SHELL ECHO>\n"); ast_add_seq_shellecho($1);}
	|functioncall EOS				{if(PARSERVERBOSE())printf("\t<SEQUENTIAL CONSTRUCT: FUNCTIONCALL>\n"); ast_add_seq_functioncall($1);}
	|assignments EOS				{if(PARSERVERBOSE())printf("\t<SEQUENTIAL CONSTRUCT: VARIABLE ASSIGNMENT>\n"); ast_add_seq_varassignment();}
	|return_statement EOS				{if(PARSERVERBOSE())printf("\t<SEQUENTIAL CONSTRUCT: RETURN STATEMENT>\n"); ast_add_seq_return();}
	;

selective_constructs:
	ifblock elseifblocks elseblock			{if(PARSERVERBOSE())printf("\t<SELECTIVE: IF ELSEIF ELSE BLOCKS>\n");}
	|ifblock elseifblocks				{if(PARSERVERBOSE())printf("\t<SELECTIVE: IF ELSEIF BLOCKS>\n");}
	|ifblock elseblock				{if(PARSERVERBOSE())printf("\t<SELECTIVE: IF ELSE BLOCKS>\n");}
	|ifblock					{if(PARSERVERBOSE())printf("\t<SELECTIVE: IF ONLY BLOCK>\n");}
	;

ifblock:
	IF PARANOPEN conditions PARANCLOSE enclosement	{if(PARSERVERBOSE())printf("\t<IF BLOCK>\n"); ast_add_sel_if();}

elseblock:
	ELSE enclosement				{if(PARSERVERBOSE())printf("\t<ELSE BLOCK>\n"); ast_add_sel_else();}

elseifblocks:
	ELIF PARANOPEN conditions PARANCLOSE enclosement		{if(PARSERVERBOSE())printf("\t<ELSEIF BLOCK: ONE>\n"); ast_add_sel_elif();}
	|elseifblocks ELIF PARANOPEN conditions PARANCLOSE enclosement	{if(PARSERVERBOSE())printf("\t<ELSEIF BLOCK: RECURSIVE>\n");}
	;

iterative_constructs:
	whileloop					{if(PARSERVERBOSE())printf("\t<ITERATIVE CONSTRUCTS: WHILE LOOP>\n");}
	|forloop					{if(PARSERVERBOSE())printf("\t<ITERATIVE CONSTRUCTS: FOR LOOP>\n");}
	;



/* Map variables declaration code syntax */
mapvariables_declaration:
	MAPDECL map_variablelist			{if(PARSERVERBOSE())printf("\t<MAPVARIABLE DECLARATIONS: MAP VAR LIST>\n");}
	;

map_variablelist:
	map_discrete_variable				{if(PARSERVERBOSE())printf("\t<MAPVARIABLELIST: DISCRETE VARIABLE FOUND>\n");}
	|map_variablelist COMMA map_discrete_variable	{if(PARSERVERBOSE())printf("\t<MAPVARIABLELIST: COMMA DISCRETE>\n");}
	;

map_discrete_variable:
	VARNAME						{if(PARSERVERBOSE())printf("\t<MAP DISCRETE VARIABLE: VARNAME FOUND| %s>\n", $1); ast_add_mapdeclnode($1);}
	|VARNAME ASSIGN BROPEN keyvalpairs BRCLOSE	{if(PARSERVERBOSE())printf("\t<MAP DISCRETE VARIABLE: KEYVALPAIRS| %s>\n", $1); ast_add_mapdeclnode($1);}
	;

keyvalpairs:
	keytype IS datatype				{if(PARSERVERBOSE())printf("\t<KEYVALPAIRS: FOUND DISCRETE>\n"); ast_make_keyvalpair($1,$3);}
	|keyvalpairs COMMA keytype IS datatype		{if(PARSERVERBOSE())printf("\t<KEYVALPAIRS: FOUND COMMA>\n"); ast_make_keyvalpair($3,$5);}
	|datatype					{if(PARSERVERBOSE())printf("\t<KEYVALPAIRS: FOUND JUST DATATYPE>\n"); ast_make_keyvalpair($1, "0");}
	|keyvalpairs COMMA datatype			{if(PARSERVERBOSE())printf("\t<KEYVALPAIRS: FOUND COMMA JUST DATATYPE>\n"); ast_make_keyvalpair($3, "0");}
	;

keytype:
	STRING						{if(PARSERVERBOSE())printf("\t<KEYTYPE: STRING>\n");}
	|NSTRING					{if(PARSERVERBOSE())printf("\t<KEYTYPE: NSTRING>\n");}
	;

datatype:
	STRING						{if(PARSERVERBOSE())printf("\t<DATATYPE: STRING>\n");}
	|NSTRING					{if(PARSERVERBOSE())printf("\t<DATATYPE: NSTRING>\n");}
	;



/* General variables declaration code syntax */
generalvariables_declaration:
	VARDECL gen_variablelist			{if(PARSERVERBOSE())printf("\t<GENVARIABLE DECLARATIONS: GEN VAR LIST>\n");}
	;

gen_variablelist:
	gen_discrete_variable				{if(PARSERVERBOSE())printf("\t<GENVARIABLE DECLARATIONS: DISCRETE VARIABLE FOUND>\n");}
	|gen_variablelist COMMA gen_discrete_variable	{if(PARSERVERBOSE())printf("\t<GENVARIABLE DECLARATIONS: COMMA DISCRETE>\n");}
	;

gen_discrete_variable:
	VARNAME						{if(PARSERVERBOSE())printf("\t<GEN DISCRETE VARIABLE: VARNAME| New variable %s>\n", $1); ast_make_vardecl_assignment($1, "0");}
	|VARNAME ASSIGN expression			{if(PARSERVERBOSE())printf("\t<GEN DISCRETE VARIABLE: VARNAME ASSIGN EXPRESSION| New variable %s with value %s>\n", $1, $3);ast_make_vardecl_assignment($1, "1");}
	|MELNAME					{if(PARSERVERBOSE())printf("\t<GEN DISCRETE VARIABLE: MELNAME| New mapelement %s>\n", $1); ast_make_vardecl_assignment($1, "0");}
	|MELNAME ASSIGN expression			{if(PARSERVERBOSE())printf("\t<GEN DISCRETE VARIABLE: MELNAME ASSIGN EXPRESSION| New element %s with val %s>\n",$1, $3); ast_make_vardecl_assignment($1, "1");}
	;



/* Variable assignment sequential constructs */
assignments:
	VARNAME ASSIGN expression			{if(PARSERVERBOSE())printf("\t<ASSIGNMENT: VARNAME ASSIGN EXPRESSION>\n"); ast_add_varassignment_expr($1);}
	|MELNAME ASSIGN expression			{if(PARSERVERBOSE())printf("\t<ASSIGNMENT: MELNAME ASSIGN EXPRESSION>\n"); ast_add_varassignment_expr($1);}
	|VARNAME ASSIGN BROPEN keyvalpairs BRCLOSE	{if(PARSERVERBOSE())printf("\t<ASSIGNMENT: VARNAME ASSIGN KEYVALPAIRS>\n"); ast_add_varassignment_keyvalpairs($1);}
	|DECR assignmentvar				{if(PARSERVERBOSE())printf("\t<ASSIGNMENT: PRE OPERATION DECR>\n"); ast_add_varassignmenttype($2,ASSIGN_PREDECR);}
	|INCR assignmentvar				{if(PARSERVERBOSE())printf("\t<ASSIGNMENT: PRE OPERATION INCR>\n"); ast_add_varassignmenttype($2,ASSIGN_PREINCR);}
	|assignmentvar DECR				{if(PARSERVERBOSE())printf("\t<ASSIGNMENT: POST OPERATION DECR>\n"); ast_add_varassignmenttype($1,ASSIGN_POSTDECR);}
	|assignmentvar INCR				{if(PARSERVERBOSE())printf("\t<ASSIGNMENT: POST OPERATION INCR>\n"); ast_add_varassignmenttype($1,ASSIGN_POSTINCR);}
	;

assignmentvar:
	VARNAME						{if(PARSERVERBOSE())printf("\t<ASSIGNMENTVAR: VARNAME>\n");}
	|MELNAME					{if(PARSERVERBOSE())printf("\t<ASSIGNMENTVAR: MELNAME>\n");}
	;


/* Arithmetic and otherwise */

expression:
	expression2						{if(PARSERVERBOSE())printf("\t<EXPRESSION: EXPRESSION2>\n"); ast_add_expr_expr2();}
	|expression ADD expression2				{if(PARSERVERBOSE())printf("\t<EXPRESSION: ADD EXPRESSION2>\n"); ast_add_expr_op_expr2(OP_ADD);}
	|expression SUB expression2				{if(PARSERVERBOSE())printf("\t<EXPRESSION: SUB EXPRESSION2>\n"); ast_add_expr_op_expr2(OP_SUB);}
	;

expression2:
	expression3						{if(PARSERVERBOSE())printf("\t<EXPRESSION2: EXPRESSION3>\n"); ast_add_expr2_expr3();}
	|expression2 MUL expression3				{if(PARSERVERBOSE())printf("\t<EXPRESSION2: MUL EXPRESSION3>\n"); ast_add_expr2_op_expr3(OP_MUL);}
	|expression2 DIV expression3				{if(PARSERVERBOSE())printf("\t<EXPRESSION2: DIV EXPRESSION3>\n"); ast_add_expr2_op_expr3(OP_DIV);}
	|expression2 TRUNCDIV expression3			{if(PARSERVERBOSE())printf("\t<EXPRESSION2: TRUNCDIV EXPRESSION3>\n"); ast_add_expr2_op_expr3(OP_TRUNCDIV);}
	;

expression3:
	expr_unary_preceder PARANOPEN expression PARANCLOSE expr_successor	{$$ = $3; if(PARSERVERBOSE())printf("\t<EXPRESSION3: UNARYPREC EXPRESSION EXPRSUCC>\n"); ast_add_expr3_unprecexprsucc();}
	|expr_unary_preceder discrete_term expr_successor	{$$ =$2; if(PARSERVERBOSE())printf("\t<EXPRESSION3: UNARYPREC TERM EXPRSUCC>\n"); ast_add_expr3_unprecdiscrsucc();}
	;

expr_unary_preceder:
	%empty							{if(PARSERVERBOSE())printf("\t<EXPR UNARY PREC: NONE>\n"); ast_add_expr3_unprec(UNARY_POS);}
	|SUB							{if(PARSERVERBOSE())printf("\t<EXPR UNARY PREC: NEGATIVE>\n"); ast_add_expr3_unprec(UNARY_NEG);}
	|ADD							{if(PARSERVERBOSE())printf("\t<EXPR UNARY PREC: POSITIVE>\n"); ast_add_expr3_unprec(UNARY_POS);}
	;

expr_successor:
	%empty							{if(PARSERVERBOSE())printf("\t<EXPR UNARY SUCC: NONE>\n");}
	|EXCLAMATION						{if(PARSERVERBOSE())printf("\t<EXPR UNARY SUCC: FACTORIAL>\n");}
	|EXP discrete_term					{if(PARSERVERBOSE())printf("\t<EXPR UNARY SUCC: EXPONENTIAL>\n");}
	|EXP PARANOPEN expression PARANCLOSE			{if(PARSERVERBOSE())printf("\t<EXPR UNARY SUCC: EXPONENTIAL EXPR>\n");}
	;

discrete_term:
	VARNAME							{if(PARSERVERBOSE())printf("\t<DISCRETE TERM: VARNAME>\n"); ast_add_expr3_discrete_term_variable($1);}
	|MELNAME						{if(PARSERVERBOSE())printf("\t<DISCRETE TERM: MELNAME>\n"); ast_add_expr3_discrete_term_variable($1);}
	|STRING							{if(PARSERVERBOSE())printf("\t<DISCRETE TERM: STRING>\n"); ast_add_expr3_discrete_term_string($1);}
	|NSTRING						{if(PARSERVERBOSE())printf("\t<DISCRETE TERM: NSTRING>\n"); ast_add_expr3_discrete_term_string($1);}
	|ARGVAR							{if(PARSERVERBOSE())printf("\t<DISCRETE TERM: ARGVAR>\n"); ast_add_expr3_discrete_term_variable($1);}
	|functioncall						{if(PARSERVERBOSE())printf("\t<DISCRETE TERM: FUNCTIONCALL>\n"); ast_add_expr3_discrete_term_functioncall($1);}
	|SHELLECHO						{if(PARSERVERBOSE())printf("\t<DISCRETE TERM: SHELLECHO>\n"); ast_add_expr3_discrete_term_shellecho($1);}
	;



/* Boolean conditions set */
conditions:
	conditions_and_only				{if(PARSERVERBOSE())printf("\t<CONDITIONS: AND ONLY CONDITION>\n"); ast_add_condition1_condition2();}
	|conditions LOR conditions_and_only		{if(PARSERVERBOSE())printf("\t<CONDITIONS: LOR AND CONDITION>\n"); ast_add_condition1_lor_condition2();}
	;

conditions_and_only:
	discrete_condition				{if(PARSERVERBOSE())printf("\t<AND ONLY CONDITION: DISCRETE CONDITION>\n"); ast_add_condition2_condition3();}
	|conditions_and_only LAND discrete_condition	{if(PARSERVERBOSE())printf("\t<AND ONLY CONDITION: LAND AND CONDITION>\n"); ast_add_condition2_land_condition3();}
	;

discrete_condition:
	unary_condition_opr PARANOPEN conditions PARANCLOSE	{if(PARSERVERBOSE())printf("\t<DISCRETE CONDITION: UNARY PARAN CONDITION>\n"); ast_add_discrete_condition_unarycondition();}
	|conditioncomponent relopr conditioncomponent	{if(PARSERVERBOSE())printf("\t<DISCRETE CONDITION: CONDITIONCOMP REL CONDITIONCOMP>\n"); ast_add_discrete_condition_comp_rel_comp();}
	|conditioncomponent				{if(PARSERVERBOSE())printf("\t<DISCRETE CONDITION: CONDITIONCOMP>\n"); ast_add_discrete_condition_comp();}
	;

unary_condition_opr:
	EXCLAMATION					{if(PARSERVERBOSE())printf("\t<NOT FOUND: UNARY TO CONDITION>\n"); ast_add_condition_unary(NEG_YES);}
	|%empty						{if(PARSERVERBOSE())printf("\t<NO UNARY TO CONDITION>\n");}
	;

conditioncomponent:
	functioncall					{if(PARSERVERBOSE())printf("\t<CONDITIONCOMPONENT: FUNCTIONCALL>\n"); ast_add_condition_component_functioncall($1);}
	|SHELLECHO					{if(PARSERVERBOSE())printf("\t<CONDITIONCOMPONENT: SHELLECHO>\n"); ast_add_condition_component_shellecho($1);}
	|MELNAME					{if(PARSERVERBOSE())printf("\t<CONDITIONCOMPONENT: MELNAME>\n"); ast_add_condition_component_varname($1);}
	|VARNAME					{if(PARSERVERBOSE())printf("\t<CONDITIONCOMPONENT: VARNAME>\n"); ast_add_condition_component_varname($1);}
	|NSTRING					{if(PARSERVERBOSE())printf("\t<CONDITIONCOMPONENT: NSTRING>\n"); ast_add_condition_component_string($1);}
	|STRING						{if(PARSERVERBOSE())printf("\t<CONDITIONCOMPONENT: STRING>\n"); ast_add_condition_component_string($1);}
	;

relopr:
	EQ						{if(PARSERVERBOSE())printf("\t<RELOPR: EQ>\n"); ast_add_condition_relopr(REL_EQ);}
	|NQ						{if(PARSERVERBOSE())printf("\t<RELOPR: NQ>\n"); ast_add_condition_relopr(REL_NQ);}
	|LT						{if(PARSERVERBOSE())printf("\t<RELOPR: LT>\n"); ast_add_condition_relopr(REL_LT);}
	|GT						{if(PARSERVERBOSE())printf("\t<RELOPR: GT>\n"); ast_add_condition_relopr(REL_GT);}
	|LE						{if(PARSERVERBOSE())printf("\t<RELOPR: LE>\n"); ast_add_condition_relopr(REL_LE);}
	|GE						{if(PARSERVERBOSE())printf("\t<RELOPR: GE>\n"); ast_add_condition_relopr(REL_GE);}
	;


/* Functioncall set */
functioncall:
	GSTRING PARANOPEN funccallargs PARANCLOSE	{if(PARSERVERBOSE())printf("\t<FUNCTION CALL>\n"); $$=$1;}

funccallargs:
	%empty						{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS: NONE>\n");}
	|discrete_argument				{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS: DISCRETE ARGUMENT>\n"); ast_add_argument_to_llhead();}
	|funccallargs COMMA discrete_argument		{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS: COMMA DISCRETE ARGUMENT>\n"); ast_add_argument_to_llnode();}
	;

discrete_argument:
	NSTRING						{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS : NSTRING>\n"); ast_add_arguments_string($1);}
	|STRING						{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS : STRING>\n"); ast_add_arguments_string($1);}
	|VARNAME					{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS : VARNAME>\n"); ast_add_arguments_varname($1);}
	|ARGVAR						{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS : ARGVAR>\n"); ast_add_arguments_varname($1);}
	|MELNAME					{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS : MELNAME>\n"); ast_add_arguments_varname($1);}
	|functioncall					{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS : FUNCTIONCALL>\n"); ast_add_arguments_functioncall($1);}
	|SHELLECHO					{if(PARSERVERBOSE())printf("\t<FUNCTION CALL ARGUMENTS : SHELLECHO>\n"); ast_add_arguments_shellecho($1);}
	;

/* Return statement */
return_statement:
	RETURN BROPEN keyvalpairs BRCLOSE		{if(PARSERVERBOSE())printf("\t<RETURN KEYVALPAIRS>\n");}
	|RETURN expression				{if(PARSERVERBOSE())printf("\t<RETURN EXPRESSION>\n"); ast_set_returnval_expression();}
	;


/* Iterative while */
whileloop:
	WHILE PARANOPEN conditions PARANCLOSE enclosement	{if(PARSERVERBOSE())printf("\t<WHILE LOOP>\n");}
	;


/* Iterative for */
forloop:
	FOR PARANOPEN forinit EOS conditions EOS forvarmodif PARANCLOSE enclosement	{if(PARSERVERBOSE())printf("\t<FOR LOOP>\n");}
	;

forinit:
	%empty						{if(PARSERVERBOSE())printf("\t<FORINIT: EMPTY>\n");}
	|generalvariables_declaration			{if(PARSERVERBOSE())printf("\t<FORINIT: GENVARIABLES DECLARATIONS>\n");}
	|mapvariables_declaration			{if(PARSERVERBOSE())printf("\t<FORINIT: MAPVARIABLES DECLARATIONS>\n");}
	|assignments					{if(PARSERVERBOSE())printf("\t<FORINIT: ASSIGNMENTS>\n");}
	;

forvarmodif:
	%empty						{if(PARSERVERBOSE())printf("\t<FORVARMODIF: EMPTY>\n");}
	|assignments					{if(PARSERVERBOSE())printf("\t<FORVARMODIF: ASSIGNMENTS>\n");}
	;

/*alltokens: IS|RETURN|BREAK|CONTINUE|FOR|ADD|INCR|SUB|DECR|MUL|EXP|DIV|TRUNCDIV|MAPDECL|VARDECL|VARNAME|MELNAME|ARGVAR|NSTRING|GSTRING|STRING|BROPEN|BRCLOSE|SHELLECHO|FUNC|IF|ELIF|ELSE|WHILE|EOS|PARANOPEN|PARANCLOSE|ASSIGN|FUNCCALL|COMMA|GT|LT|EQ|NQ|GE|LAND|LOR|LE|ERR|EOL;*/
%%

int yyerror(const char *s){
	fprintf(stdout, "{{error: %s}}\n", s);
	return 0;
}
