/* HLANG INTERPRETER development stage 0 
 * created by SUPRAGYA RAJ
 */

%option noyywrap
%x _MLCMNT _FUNCTION _STRING _SHELLECHO
%{
#include <string.h>
#define TESTFOLDER "tests/"
#define VERSION 0.01
#define DEBUG 1
char yylval[2000];


/* DEFINING TYPES 
 * Anything that does not matches the above is shown as **E{string}** during tests
 */

enum yytokentype{
	MAPDECL		=	601,
	VARDECL		=	602,
	VARNAME		=	603,
	MELNAME		=	604,
	ARGVAR		=	605,
	NVAL		=	606,
	STRING		=	607,
	BROPEN		=	610,
	BRCLOSE		=	611,
	SHELLECHO	=	612,
	FUNC		=	613,
	IF		=	614,
	ELIF		=	615,
	ELSE		=	616,
	WHILE		=	617,
	EOS		=	618,
	PARANOPEN	=	619,
	PARANCLOSE	=	620,
	ASSIGN		=	621,
	FUNCCALL	=	622,
	COMMA		=	623,
	GT		=	624,
	LT		=	625,
	EQ		=	626,
	NQ		=	627,
	GE		=	628,
	LE		=	629
};

void strclean(char *str);
void strcpy(char *str1, char *str2);
%}

%%

"declare"[ \t\n]*"map"					{strclean(yylval); return MAPDECL;}
"declare"						{strclean(yylval); return VARDECL;}
[$][_a-zA-Z][_a-zA-Z0-9]+				{strcpy(yylval, yytext+1); return VARNAME;}
[$][_a-zA-Z][_a-zA-Z0-9]+"["[a-zA-Z0-9]+"]"		{strcpy(yylval, yytext+1); return MELNAME;}
[$][0-9]+						{strcpy(yylval, yytext+1); return ARGVAR;}
([0-9]+|[0-9]+[.][0-9]*|[.][0-9]+)			{strcpy(yylval, yytext); return NVAL;}

["]							{strclean(yylval); BEGIN _STRING;}
<_STRING>["]						{BEGIN INITIAL; return STRING}
<_STRING>.						{strappend(yylval, yytext);}

[#][^*].*[^\n]						/*Single line comments, do nothing */
[{]							{strclean(yylval); return BROPEN;}
[}]							{strclean(yylval); return BRCLOSE;}

"<%"							{strclean(yylval); BEGIN _SHELLECHO;}
<_SHELLECHO>">"						{BEGIN INITIAL; return SHELLECHO;}
<_SHELLECHO>.						{strappend(yylval, yytext);}								

"function"						{strclean(yylval); BEGIN _FUNCTION;}
<_FUNCTION>[ \t\n]+					 /*Eat these up */
<_FUNCTION>[a-zA-Z][a-zA-Z0-9]*				{strappend(yylval, yytext); BEGIN INITIAL;}

"#*"							{BEGIN _MLCMNT;}
<_MLCMNT>([^*]|\n)+|.					/* Do nothing */
<_MLCMNT><<EOF>>					/* Error, but treat as if nothing happened */
<_MLCMNT>"*#"						{BEGIN INITIAL;}

"if"							{return IF;}
"elif"							{return ELIF;}
"else"							{return ELSE;}
"while"							{return WHILE;}

[a-zA-Z][a-zA-Z0-9]*"("					{return FUNC;}
[(]							{return PARANOPEN;}
[)]							{return PARANCLOSE;}	

">"							{return GT;}
"<"							{return LT;}
"=="							{return EQ;}
"!="|"<>"						{return NE;}
">="							{return GE;}
"<="							{return LE;}

[=]							{return ASSIGN;}
[;]							{return EOS;}
[,]							{return COMMA;}
[ \t]							/* Eat up whitespaces */
							/* [\n] NEWLINE REMOVER TO BE INSERTED */
.							{return ERR; } 

%%

int main(char **argv){
	/* Debug welcome */
	DEBUG?printf("+--------------------------\n"):0;
	DEBUG?printf("|HLANG LEXER %0.2f\n", VERSION):0;
	DEBUG?printf("+--------------------------\n"):0;
	
	/* Lexing done here */
	int tok;
	while(tok = yylex()){
		printf("%d ", tok);
		if(has_lval(tok)){
			printf(yylval);
		}
		printf("\n ");
		if(tok == FUNC){
			printf("%d", PARANOPEN);
		}
	}	
	DEBUG?printf(">>>Hlang lexer completes\n"):0;
	return 0;
}

void strclean(char *str){
	/*Cleans a given string, just adds '\0' in the 0th position */
	str[0] = '\0';	
}

void strappend(char *str1, char *str *str2){
	
}








