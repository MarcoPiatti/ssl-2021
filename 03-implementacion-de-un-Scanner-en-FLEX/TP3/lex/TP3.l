%option noyywrap
%option yylineno
%option warn

%{

#include "lexemelist.h"
#include "writers.h"

#include <stdio.h>
#include <string.h>

typedef enum token {
    IDENTIFICADOR, 
    LITERAL_CADENA, 
    KEYWORD, 
    CTE_OCT, 
    CTE_HEX, 
    CTE_DEC,
    CTE_REAL, 
    CTE_CHAR, 
    PUNTUADOR, 
    COMENTARIO, 
    DIRECTIVA, 
    NO_RECONOCIDO, 
    MAX_TOKENS
} t_token;

t_lexeme_list* listas[MAX_TOKENS];

void instanciar_listas() {
    for( t_token i = IDENTIFICADOR; i < MAX_TOKENS; i++){
        listas[i] = lexeme_list_create();
    }
}

void mostrar_listas_en(FILE* output) {
    lexeme_list_write (listas[IDENTIFICADOR] , output, "Identificadores"                      , as_frequency_count);
    lexeme_list_write (listas[LITERAL_CADENA], output, "Literales Cadena"                     , as_string_literal );
    lexeme_list_write (listas[KEYWORD]       , output, "Palabras Reservadas"                  , as_keyword        );
    lexeme_list_write (listas[CTE_OCT]       , output, "Constantes Octales"                   , as_oct            );
    lexeme_list_write (listas[CTE_HEX]       , output, "Constantes Hexadecimales"             , as_hex            );
    lexeme_list_write (listas[CTE_DEC]       , output, "Constantes Decimales"                 , as_is             );
    
    lexeme_list_write_sum (listas[CTE_DEC], output);

    lexeme_list_write (listas[CTE_REAL]      , output, "Constantes Reales"                    , as_real           );
    lexeme_list_write (listas[CTE_CHAR]      , output, "Constantes Caracter"                  , as_is             );
    lexeme_list_write (listas[PUNTUADOR]     , output, "Caracteres De Puntuacion / Operadores", as_frequency_count);
    lexeme_list_write (listas[COMENTARIO]    , output, "Comentarios"                          , as_comment        );
    lexeme_list_write (listas[DIRECTIVA]     , output, "Directivas Define e Include"          , as_is             );
    lexeme_list_write (listas[NO_RECONOCIDO] , output, "Cadenas No Reconocidas"               , as_unrecognized   );
}

void destruir_listas() {
    for( t_token i = IDENTIFICADOR; i < MAX_TOKENS; i++){
        lexeme_list_destroy(listas[i]);
    }
}

/* Buffer con la ultima cadena no reconocida */
char unrecognized[1024];
int  unrecognized_chars = 0;

/* Al matchear una expresion "correcta", agrega el contenido del buffer
 * a la lista de cadenas no reconocidas */
void good_match() {
    if(unrecognized_chars) {
        lexeme_list_add_with_uint(listas[NO_RECONOCIDO], unrecognized, yylineno);
        memset(unrecognized, 0, sizeof unrecognized);
        unrecognized_chars = 0;
    }
}

%}

alpha                       [a-zA-Z]
nondigit                    {alpha}|_

digit		                [0-9]
nonzero                     [1-9]
hexdigit                    [0-9a-fA-F]
prefijo_hex                 0[xX]
octdigit                    [0-7]

keyword_otro                extern|inline|sizeof
keyword_control             break|case|continue|default|do|else|for|goto|if|return|switch|while
keyword_type                auto|char|const|double|enum|float|int|long|register|restrict|short|signed|static|struct|typedef|union|unsigned|void|volatile|_Bool|_Complex|_Imaginary

identificador               {identificador_nondigit}({identificador_nondigit}|{digit})*
identificador_nondigit      {nondigit}|{caracter_universal}
caracter_universal          \\[uU]{hex_quad}{1,2}
hex_quad                    {hexdigit}{4}

const_entero                ({entero_dec}|{entero_hex}|{entero_oct}){sufijo_entero}?
entero_dec		            {nonzero}{digit}*{sufijo_entero}?
entero_hex                  {prefijo_hex}{hexdigit}+{sufijo_entero}?
entero_oct                  0{octdigit}*{sufijo_entero}?
sufijo_entero               [uU]([lL]|ll|LL)?|([lL]|ll|LL)[uU]?

const_float                 {float_dec}|{float_hex}
float_dec                   ({significando_dec}{exponente_dec}?|{digit}+{exponente_dec})[fFlL]?
float_hex                   {prefijo_hex}({significando_hex}|{hexdigit}+){exponente_hex}[fFlL]?
significando_dec            {digit}*"."{digit}+|{digit}+"."
significando_hex            {hexdigit}*"."{hexdigit}+|{hexdigit}+"."
exponente_dec               [eE]{exponente}
exponente_hex               [pP]{exponente}
exponente                   [\+\-]?{digit}+

const_char                  L?[']{c_char}+[']
c_char                      [^\'\\\n]|{escape}

literal_cadena              L?\"{s_char}*\"
s_char                      [^\"\\\n]|{escape}

escape                      {escape_simple}|{escape_oct}|{escape_hex}|{caracter_universal}
escape_simple               \\[abfnrtv\'\"\?\\]
escape_oct                  \\{octdigit}{1,3}
escape_hex                  \\x{hexdigit}+

puntuador                   "["|"]"|"("|")"|"{"|"}"|"."|"->"|"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"|"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"|"?"|":"|";"|"..."|"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^="|"|="|","|"#"|"##"|"<:"|":>"|"<%"|"%>"|"%:"|"%:%:"

comentario_sl               "//".*
comentario_ml               "/*"([^*]|(\*+[^*/]))*"*"+"/"

directiva                   {directiva_include}|{directiva_define}
directiva_include           [ \t]*#include([ \t]+{pre_token})+[ \t]*\n
directiva_define            [ \t]*#define[ \t]+{identificador}([ \t]*"("[ \t]*({lista_id}|...|{lista_id}[ \t]*,[ \t]*...)?[ \t]*")")?([ \t]+{pre_token})*[ \t]*\n
lista_id                    {identificador}(,{identificador})*
pre_token                   {header}|{identificador}|{pre_number}|{const_char}|{literal_cadena}|{puntuador}
header                      \<[^\>\n]+\>|\"[^\"\n]+\"
pre_number                  "."?{digit}("."|{digit}|{identificador_nondigit}|[eEpP][\+\-])*

%%

{puntuador}                 { good_match(); lexeme_list_add_as_frequency_count  (listas[PUNTUADOR]      , yytext                            ); }
{keyword_otro}              { good_match(); lexeme_list_add_with_string         (listas[KEYWORD]        , yytext, "Otros"                   ); }
{keyword_control}           { good_match(); lexeme_list_add_with_string         (listas[KEYWORD]        , yytext, "Estructuras de control"  ); }
{keyword_type}              { good_match(); lexeme_list_add_with_string         (listas[KEYWORD]        , yytext, "Tipo de dato"            ); }
{identificador}             { good_match(); lexeme_list_add_as_frequency_count  (listas[IDENTIFICADOR]  , yytext                            ); }
{literal_cadena}            { good_match(); lexeme_list_add_simple_length_sorted(listas[LITERAL_CADENA] , yytext                            ); }
{entero_oct}                { good_match(); lexeme_list_add_simple              (listas[CTE_OCT]        , yytext                            ); }
{entero_hex}                { good_match(); lexeme_list_add_simple              (listas[CTE_HEX]        , yytext                            ); }
{entero_dec}                { good_match(); lexeme_list_add_simple              (listas[CTE_DEC]        , yytext                            ); }
{const_float}               { good_match(); lexeme_list_add_simple              (listas[CTE_REAL]       , yytext                            ); }
{const_char}                { good_match(); lexeme_list_add_simple              (listas[CTE_CHAR]       , yytext                            ); }
{comentario_ml}             { good_match(); lexeme_list_add_with_string         (listas[COMENTARIO]     , yytext, "Comentario multilinea"   ); }
{comentario_sl}             { good_match(); lexeme_list_add_with_string         (listas[COMENTARIO]     , yytext, "Comentario de una linea" ); }
^{directiva}                { good_match(); lexeme_list_add_simple              (listas[DIRECTIVA]      , yytext                            ); }
[ \t\n]                     { good_match(); }
<<EOF>>                     { good_match(); return 0; }
.                           { unrecognized[unrecognized_chars++] = yytext[0]; /* Carga el caracter al buffer no reconocido */ }

%%

int main(int argc, char **argv) {
    // Error checking en el archivo de entrada
    yyin = NULL;
    if(argc > 1)
        yyin = fopen(argv[1], "r");
    if(yyin == NULL)
        yyin = fopen("archivo.c", "r");
    if(yyin == NULL){
        fprintf(stderr, "No se encontro el archivo de entrada.\n");
        return EXIT_FAILURE;
    }
    yyout = fopen("yyout.txt", "w");
    FILE* salida = fopen("analisis_lexico.txt", "w");

    instanciar_listas();
    yylex();
    mostrar_listas_en(stdout);
    mostrar_listas_en(salida);
    destruir_listas();

    fclose(yyin);
    fclose(yyout);
    fclose(salida);

    return 0;
}