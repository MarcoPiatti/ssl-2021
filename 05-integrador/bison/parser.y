%{
    #include <stdio.h>
    int yylex(void);
    int yyerror(const char *s);
    extern FILE* yyin;
    extern int yylineno;
%}

/* No hay Constantes caracter por el momento, la BNF del vol. 1 no las contempla, las variables char igual existen ya que son numeros */
/* No hay literales cadena por el momento, la BNF del vol. 1 no las contempla */
/* No se considera el switch, la BNF del vol. 1 no contempla la keyword */

typedef enum types { t_char, t_int, t_double, t_ptr } types;

typedef union val {
    char cval;
    int ival;
    double dval;
    unsigned int pval;
} val;

typedef struct num {
    types type;
    val value;
} num;

%union
{
    char* strval;
    num numval;
}

%token CHAR
%token DO
%token DOUBLE
%nonassoc ELSE
%token FLOAT
%token IF
%nonassoc IFX
%token INT
%token LONG
%token RETURN
%token SIZOF
%token STRUCT
%token TYPEDEF
%token VOID
%token WHILE

%token MASMAS "++"
%token MENOR_IGUAL "<="
%token IGUALIGUAL "=="
%token DIFERENTE "!="
%token AND "&&"
%token OR "||"
%token ASIGN_SUM "+="

%token <strval> IDENTIFIER
%token <numval> INT_CONST
%token <numval> REAL_CONST

%start primary_expression

%%

identificador: IDENTIFIER ;

constante:     INT_CONST
            | REAL_CONST
            ;

operador:     '++' | '*' | '+' | '&' | '!' | SIZEOF | '/' | '%' | '<' 
            | "<=" | "==" | "!=" | "&&" | "||" | "?:" | '=' | "+=" ;

puntuador: '(' | ')' | '{' | '}' | ',' | ';' ;

expresion: expAsignacion ;

expAsignacion:   expCondicional
                | expUnaria operAsignacion expAsignacion
                ;

operAsignacion: '=' | "+=" ;

expCondicional:   expOr
                | expOr '?' expresion ':' expCondicional
                ;

expOr:    expAnd
        | expOr "||" expAnd
        ;

expAnd:   expIgualdad
        | expAnd "&&" expIgualdad
        ;

expIgualdad:      expRelacional
                | expIgualdad operIgualdad expRelacional
                ;

operIgualdad: "==" | "!=" ;

expRelacional:    expAditiva
                | expRelacional operRelacional expAditiva
                ;

operRelacional: '<' | "<=" ;

expAditiva:       expMultiplicativa
                | expAditiva '+' expMultiplicativa
                ;

expMultiplicativa:    expUnaria
                    | expMultiplicativa '*' expUnaria
                    ;

expUnaria:    expPostfijo
            | "++" expUnaria
            | operUnario expUnaria
            | SIZEOF '(' nombreTipo ')'
            ;

operUnario: '&' | '*' | '-' | '!' ;

expPostfijo:      expPrimaria
                | expPostfijo '[' expresion ']'
                | expPostfijo '(' listaArgumentos_opt ')'

listaArgumentos_opt:      /* empty */
                        | listaArgumentos
                        ;

listaArgumentos:      expAsignacion
                    | listaArgumentos ',' expAsignacion
                    ;

expPrimaria:      identificador
                | constante
                | '(' expresion ')'
                ;

nombreTipo: CHAR | INT | DOUBLE ;

declaVarSimples: nombreTipo listaVarSimples ';' ;

listaVarSimples:      unaVarSimple
                    | listaVarSimples ',' unaVarSimple 
                    ;

unaVarSimple: variable inicial_opt ;

variable: identificador ;

inicial_opt:      /* empty */
                | inicial
                ;

inicial: '=' constante ;

sentencia:    sentCompuesta
            | sentExpresion
            | sentSeleccion
            | sentIteracion
            | sentSalto
            ;

sentCompuesta:    '{' listaDeclaraciones_opt listaSentencias_opt '}'

listaDeclaraciones_opt:   /* empty */
                        | listaDeclaraciones
                        ;

listaSentencias_opt:      /* empty */
                        | listaSentencias
                        ;

listaDeclaraciones:   declaracion
                    | listaDeclaraciones declaracion
                    ;

listaSentencias:      sentencia
                    | listaSentencias sentencia
                    ;

sentExpresion: expresion_opt ;

expresion_opt:    /* empty */
                | expresion
                ;

sentSeleccion:    IF '(' expresion ')' sentencia else_opt
                ;

else_opt:     %prec IFX
            | ELSE sentencia
            ;

sentIteracion:    WHILE '(' expresion ')' sentencia
                | DO sentencia WHILE '(' expresion ')' ';'
                | for '(' expresion_opt ';' expresion_opt ';' expresion_opt ')' sentencia
                ;

sentSalto:  RETURN expresion_opt ';' ;